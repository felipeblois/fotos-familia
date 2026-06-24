"""
NEVIIM — Middleware de Log de Auditoria.

Registra em formato JSON estruturado (AU01-AU03):
- Campos obrigatórios: timestamp UTC, action, actor_uid, resource_id, ip_hash
- Aplica hash no IP (SHA-256 truncado) para conformidade LGPD (R5)
- Rotas sensíveis: todos os endpoints /api/v1/admin/*
- Erros 4xx/5xx sempre logados
- Nunca loga dados pessoais em claro (R5)

Em produção, o Cloud Logging Agent captura o stdout em JSON
e envia ao Google Cloud Logging (AU03).
"""

import hashlib
import time
import uuid
from datetime import datetime, timezone

import structlog
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = structlog.get_logger()

# Prefixos de rotas que sempre geram log de auditoria
_ALWAYS_AUDIT = {
    "/api/v1/admin",
    "/api/v1/albums",
}


def _hash_ip(ip: str) -> str:
    """Aplica SHA-256 truncado a 16 chars no IP — evita log de dado pessoal (R5, AU02)."""
    return hashlib.sha256(ip.encode()).hexdigest()[:16]


def _extract_uid(request: Request) -> str:
    """Extrai UID do token já decodificado (se disponível no estado da request)."""
    # O uid é populado pelo middleware de auth em rotas protegidas
    return getattr(request.state, "actor_uid", "anonymous")


class AuditLogMiddleware(BaseHTTPMiddleware):
    """
    Loga ações sensíveis de forma estruturada.
    Campos AU02: timestamp, action, actor_uid, resource_id, ip_hash
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id

        start = time.perf_counter()
        client_ip = (
            request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
            or (request.client.host if request.client else "unknown")
        )
        ip_hash = _hash_ip(client_ip)
        path = request.url.path
        method = request.method

        response: Response = await call_next(request)

        duration_ms = round((time.perf_counter() - start) * 1000, 2)
        status_code = response.status_code

        # Determina se este evento deve ser auditado
        is_sensitive = any(path.startswith(prefix) for prefix in _ALWAYS_AUDIT)
        is_error = status_code >= 400

        if is_sensitive or is_error:
            actor_uid = _extract_uid(request)
            # Resource ID: última parte do path (evita log de corpo da request)
            resource_id = path.split("/")[-1] if "/" in path else path

            logger.info(
                "audit_event",
                # Campos obrigatórios AU02
                timestamp=datetime.now(timezone.utc).isoformat(),
                action=f"{method}:{path}",
                actor_uid=actor_uid,
                resource_id=resource_id,
                ip_hash=ip_hash,
                # Campos complementares
                request_id=request_id,
                status_code=status_code,
                duration_ms=duration_ms,
            )

        # Injeta request-id na resposta para rastreabilidade
        response.headers["X-Request-ID"] = request_id
        return response
