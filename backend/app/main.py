"""
Ponto de entrada da API FastAPI do projeto Neviim.

Arquitetura oficial:
- O app Flutter le albuns e fotos diretamente do Firestore.
- O backend serve operacoes administrativas, health check e automacoes.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

import structlog
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from app.config import settings
from app.middleware.audit_log import AuditLogMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.routers import admin, health, media

structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.processors.TimeStamper(fmt="iso"),
        (
            structlog.dev.ConsoleRenderer()
            if settings.ENVIRONMENT == "development"
            else structlog.processors.JSONRenderer()
        ),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(
        logging.getLevelName(settings.LOG_LEVEL)
    ),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
)

_log = structlog.get_logger()

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"],
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    _log.info(
        "neviim_api_startup",
        version=settings.APP_VERSION,
        environment=settings.ENVIRONMENT,
        rate_limit=f"{settings.RATE_LIMIT_PER_MINUTE}/min",
    )
    yield
    _log.info("neviim_api_shutdown", version=settings.APP_VERSION)


app = FastAPI(
    title="NEVIIM API",
    description=(
        "API administrativa da Paroquia Neviim para moderacao e operacoes locais."
    ),
    version=settings.APP_VERSION,
    docs_url="/docs" if settings.ENVIRONMENT == "development" else None,
    redoc_url="/redoc" if settings.ENVIRONMENT == "development" else None,
    openapi_url="/openapi.json" if settings.ENVIRONMENT == "development" else None,
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    expose_headers=["X-Request-ID"],
    max_age=86400,
)

app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(AuditLogMiddleware)

app.include_router(health.router)
app.include_router(admin.router, prefix="/api/v1")
app.include_router(media.router, prefix="/api/v1")


@app.exception_handler(Exception)
async def global_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    _log.error(
        "unhandled_exception",
        path=request.url.path,
        method=request.method,
        exc_type=type(exc).__name__,
        exc_detail=str(exc) if settings.ENVIRONMENT == "development" else "hidden",
    )

    if settings.ENVIRONMENT == "development":
        raise exc

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "internal_server_error",
            "message": "Erro interno. Por favor, tente novamente.",
            "request_id": getattr(request.state, "request_id", None),
        },
    )
