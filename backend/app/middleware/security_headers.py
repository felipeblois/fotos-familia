"""
NEVIIM — Middleware de Headers de Segurança HTTP.

Aplica em toda resposta (HE03):
- HSTS: força HTTPS por 2 anos
- X-Frame-Options: previne clickjacking
- X-Content-Type-Options: previne MIME sniffing
- Referrer-Policy: reduz vazamento de URL em redirects
- Permissions-Policy: desabilita APIs de hardware não usadas
- Content-Security-Policy: origem restrita de scripts/imagens

Referência: OWASP Secure Headers Project
"""

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.config import settings


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Injeta headers de segurança HTTP em todas as respostas."""

    # CSP configurada por ambiente
    _CSP_DEVELOPMENT = (
        "default-src 'self'; "
        "img-src 'self' https://drive.google.com https://lh3.googleusercontent.com "
        "https://drive-thirdparty.googleusercontent.com data: blob:; "
        "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "  # eval para docs/swagger
        "style-src 'self' 'unsafe-inline'; "
        "font-src 'self' data:; "
        "connect-src 'self' http://localhost:* ws://localhost:* "
        "https://*.googleapis.com https://*.firebaseio.com; "
        "frame-ancestors 'none';"
    )

    _CSP_PRODUCTION = (
        "default-src 'self'; "
        "img-src 'self' https://drive.google.com https://lh3.googleusercontent.com "
        "https://drive-thirdparty.googleusercontent.com data: blob:; "
        "script-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "font-src 'self'; "
        "connect-src 'self' https://*.googleapis.com https://*.firebaseio.com "
        "https://firebaseapp.com; "
        "frame-ancestors 'none'; "
        "upgrade-insecure-requests;"
    )

    async def dispatch(self, request: Request, call_next) -> Response:
        response: Response = await call_next(request)

        # HSTS — apenas em produção (em dev, não usamos HTTPS)
        if settings.ENVIRONMENT == "production":
            response.headers["Strict-Transport-Security"] = (
                "max-age=63072000; includeSubDomains; preload"
            )

        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=(), payment=()"
        )
        response.headers["X-XSS-Protection"] = "0"  # CSP é preferível a este header legado
        response.headers["Content-Security-Policy"] = (
            self._CSP_PRODUCTION
            if settings.ENVIRONMENT == "production"
            else self._CSP_DEVELOPMENT
        )

        # Remove headers que expõem informações do servidor
        # Starlette 1.0+ não tem .pop() em MutableHeaders — usa __delitem__
        for header in ("server", "Server", "x-powered-by", "X-Powered-By"):
            try:
                del response.headers[header]
            except KeyError:
                pass

        return response
