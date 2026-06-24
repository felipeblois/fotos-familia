"""Rotas publicas de entrega de midia."""

from __future__ import annotations

from fastapi import APIRouter, Request, Response
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.services.media_service import download_photo_bytes

router = APIRouter(prefix="/media", tags=["Media"])
_limiter = Limiter(key_func=get_remote_address)


@router.get("/albums/{album_id}/photos/{photo_id}")
@_limiter.limit("120/minute")
async def get_photo_media(
    album_id: str,
    photo_id: str,
    request: Request,
    download: bool = False,
    thumbnail: bool = False,
) -> Response:
    content, mime_type, file_name = download_photo_bytes(
        album_id,
        photo_id,
        thumbnail=thumbnail,
    )
    disposition = "attachment" if download else "inline"
    origin = request.headers.get("origin", "*")
    cache_max_age = 86400 if thumbnail else 3600

    return Response(
        content=content,
        media_type=mime_type,
        headers={
            "Cache-Control": f"public, max-age={cache_max_age}",
            "Content-Disposition": f'{disposition}; filename="{file_name}"',
            "Access-Control-Allow-Origin": origin,
            "Access-Control-Allow-Credentials": "true",
            "Cross-Origin-Resource-Policy": "cross-origin",
        },
    )
