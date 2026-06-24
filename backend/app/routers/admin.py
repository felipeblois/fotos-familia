"""Rotas administrativas do projeto Neviim."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Request
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.dependencies import verify_admin_token
from app.schemas.responses import ApiResponse
from app.services.admin_service import (
    list_album_photos,
    list_albums,
    list_audit_logs,
    soft_delete_photo,
)

router = APIRouter(prefix="/admin", tags=["Admin"])
_limiter = Limiter(key_func=get_remote_address)


@router.get(
    "/albums",
    response_model=ApiResponse,
    dependencies=[Depends(verify_admin_token)],
)
@_limiter.limit("30/minute")
async def admin_list_albums(
    request: Request,
    _admin: dict = Depends(verify_admin_token),
) -> ApiResponse:
    return ApiResponse(
        success=True,
        message="Albuns carregados com sucesso.",
        data={"albums": list_albums()},
    )


@router.get(
    "/albums/{album_id}/photos",
    response_model=ApiResponse,
    dependencies=[Depends(verify_admin_token)],
)
@_limiter.limit("30/minute")
async def admin_list_album_photos(
    album_id: str,
    request: Request,
    _admin: dict = Depends(verify_admin_token),
) -> ApiResponse:
    return ApiResponse(
        success=True,
        message="Fotos carregadas com sucesso.",
        data={"album_id": album_id, "photos": list_album_photos(album_id)},
    )


@router.delete(
    "/albums/{album_id}/photos/{photo_id}",
    response_model=ApiResponse,
    dependencies=[Depends(verify_admin_token)],
)
@_limiter.limit("20/minute")
async def admin_delete_photo(
    album_id: str,
    photo_id: str,
    request: Request,
    _admin: dict = Depends(verify_admin_token),
) -> ApiResponse:
    deleted = soft_delete_photo(album_id, photo_id, _admin.get("uid", "unknown"))
    if not deleted:
        return ApiResponse(
            success=False,
            message="Foto inexistente.",
            data={"photo_id": photo_id, "deleted": False},
        )

    return ApiResponse(
        success=True,
        message="Foto ocultada com sucesso.",
        data={"photo_id": photo_id, "album_id": album_id, "deleted": True},
    )


@router.get(
    "/audit-logs",
    response_model=ApiResponse,
    dependencies=[Depends(verify_admin_token)],
)
@_limiter.limit("10/minute")
async def admin_get_audit_logs(
    request: Request,
    _admin: dict = Depends(verify_admin_token),
) -> ApiResponse:
    return ApiResponse(
        success=True,
        message="Logs carregados com sucesso.",
        data={"logs": list_audit_logs()},
    )
