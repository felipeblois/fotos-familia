"""
NEVIIM — Router: Health Check (CO01).

Endpoint público /health que retorna:
- status: "ok"
- version: versão da API
- environment: ambiente atual
- timestamp: UTC ISO-8601

Não requer autenticação (monitoramento externo).
"""

from datetime import datetime, timezone

import structlog
from fastapi import APIRouter
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import settings
from app.schemas.responses import HealthResponse

router = APIRouter(tags=["Health"])
logger = structlog.get_logger()

# Rate limit mais permissivo para health (monitoramento externo)
_limiter = Limiter(key_func=get_remote_address)


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check da API",
    description="Verifica se o serviço está operacional. Não requer autenticação.",
    tags=["Health"],
)
async def health_check() -> HealthResponse:
    """
    Retorna status, versão e timestamp da API.
    Usado por uptime monitors, Cloud Run health probes e CI.
    CO01: Health-check endpoint obrigatório.
    """
    return HealthResponse(
        status="ok",
        version=settings.APP_VERSION,
        environment=settings.ENVIRONMENT,
        timestamp=datetime.now(timezone.utc).isoformat(),
    )
