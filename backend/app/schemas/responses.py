"""Schemas de resposta do backend Neviim."""

from typing import Any, Optional

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Resposta do endpoint /health (CO01)."""

    status: str
    version: str
    environment: str
    timestamp: str


class ApiResponse(BaseModel):
    """Resposta genérica paginável para endpoints da API."""

    success: bool
    message: str
    data: Any = None


class ErrorResponse(BaseModel):
    """Resposta de erro padronizada (HE05: sem stack trace em produção)."""

    error: str
    message: str
    request_id: Optional[str] = None
