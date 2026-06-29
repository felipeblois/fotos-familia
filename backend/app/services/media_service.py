"""Servicos de entrega de midia via backend."""

from __future__ import annotations

import io
import os
from functools import lru_cache
from pathlib import Path
from typing import Any, Optional

import httpx
from fastapi import HTTPException, status
from firebase_admin import firestore
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaIoBaseDownload

from app.config import settings
from app.dependencies import get_firebase_app


THUMBNAIL_CACHE_DIR = Path(
    os.getenv("NEVIIM_MEDIA_CACHE_DIR", "/tmp/neviim-media-cache")
) / "thumbnails"
THUMBNAIL_CACHE_MAX_MB = int(os.getenv("NEVIIM_MEDIA_CACHE_MAX_MB", "256"))


@lru_cache(maxsize=1)
def get_drive_service():
    scopes = ["https://www.googleapis.com/auth/drive.readonly"]
    sa_path = settings.FIREBASE_SERVICE_ACCOUNT_PATH

    if sa_path and os.path.exists(sa_path):
        creds = service_account.Credentials.from_service_account_file(
            sa_path,
            scopes=scopes,
        )
    else:
        raise RuntimeError(
            "FIREBASE_SERVICE_ACCOUNT_PATH nao configurado para proxy de midia."
        )

    return build("drive", "v3", credentials=creds, cache_discovery=False)


def _get_photo_document(album_id: str, photo_id: str) -> dict[str, Any]:
    get_firebase_app()
    db = firestore.client()
    snapshot = (
        db.collection("albums")
        .document(album_id)
        .collection("photos")
        .document(photo_id)
        .get()
    )

    if not snapshot.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Foto nao encontrada.",
        )

    data = snapshot.to_dict() or {}
    if data.get("is_deleted", False):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Foto indisponivel.",
        )

    return {
        "id": snapshot.id,
        "source_file_id": data.get("source_file_id", ""),
        "name": data.get("name", snapshot.id),
        "mime_type": data.get("mime_type", "application/octet-stream"),
        "thumbnail_url": data.get("thumbnail_url", ""),
    }


def _safe_cache_key(value: str) -> str:
    return "".join(
        char if char.isalnum() or char in {"-", "_"} else "_"
        for char in value
    )


def _thumbnail_cache_paths(source_file_id: str) -> tuple[Path, Path]:
    cache_key = _safe_cache_key(source_file_id)
    return (
        THUMBNAIL_CACHE_DIR / f"{cache_key}.bin",
        THUMBNAIL_CACHE_DIR / f"{cache_key}.content-type",
    )


def _read_cached_thumbnail(source_file_id: str) -> Optional[tuple[bytes, str]]:
    content_path, content_type_path = _thumbnail_cache_paths(source_file_id)
    if not content_path.exists() or not content_type_path.exists():
        return None

    return (
        content_path.read_bytes(),
        content_type_path.read_text(encoding="utf-8").strip() or "image/jpeg",
    )


def _write_cached_thumbnail(
    source_file_id: str,
    content: bytes,
    mime_type: str,
) -> None:
    THUMBNAIL_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    content_path, content_type_path = _thumbnail_cache_paths(source_file_id)
    content_path.write_bytes(content)
    content_type_path.write_text(mime_type, encoding="utf-8")
    _prune_thumbnail_cache()


def _prune_thumbnail_cache() -> None:
    if THUMBNAIL_CACHE_MAX_MB <= 0 or not THUMBNAIL_CACHE_DIR.exists():
        return

    max_bytes = THUMBNAIL_CACHE_MAX_MB * 1024 * 1024
    content_files = [
        path
        for path in THUMBNAIL_CACHE_DIR.glob("*.bin")
        if path.is_file()
    ]
    total_bytes = sum(path.stat().st_size for path in content_files)
    if total_bytes <= max_bytes:
        return

    for path in sorted(content_files, key=lambda item: item.stat().st_mtime):
        try:
            total_bytes -= path.stat().st_size
            path.unlink()
            path.with_suffix(".content-type").unlink(missing_ok=True)
        except OSError:
            continue

        if total_bytes <= max_bytes:
            return


def _looks_like_thumbnail_url(url: str) -> bool:
    return "thumbnail" in url or "googleusercontent.com" in url


def _fetch_thumbnail_bytes(photo: dict[str, Any]) -> Optional[tuple[bytes, str, str]]:
    source_file_id = photo["source_file_id"]
    if not source_file_id:
        return None

    cached_thumbnail = _read_cached_thumbnail(source_file_id)
    if cached_thumbnail is not None:
        content, mime_type = cached_thumbnail
        return content, mime_type, photo["name"]

    drive = get_drive_service()
    try:
        metadata = (
            drive.files()
            .get(fileId=source_file_id, fields="thumbnailLink")
            .execute()
        )
    except HttpError:
        metadata = {}

    thumbnail_url = metadata.get("thumbnailLink") or ""
    stored_thumbnail_url = photo.get("thumbnail_url", "")
    if not thumbnail_url and _looks_like_thumbnail_url(stored_thumbnail_url):
        thumbnail_url = stored_thumbnail_url

    if not thumbnail_url:
        return None

    try:
        with httpx.Client(follow_redirects=True, timeout=20.0) as client:
            response = client.get(thumbnail_url)
            response.raise_for_status()
    except httpx.HTTPError:
        return None

    mime_type = response.headers.get("content-type") or photo["mime_type"]
    _write_cached_thumbnail(source_file_id, response.content, mime_type)
    return response.content, mime_type, photo["name"]


def download_photo_bytes(
    album_id: str,
    photo_id: str,
    *,
    thumbnail: bool = False,
) -> tuple[bytes, str, str]:
    photo = _get_photo_document(album_id, photo_id)
    if thumbnail:
        thumbnail_content = _fetch_thumbnail_bytes(photo)
        if thumbnail_content is not None:
            return thumbnail_content

    source_file_id = photo["source_file_id"]

    if not source_file_id:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Foto sem referencia de origem no Drive.",
        )

    drive = get_drive_service()
    request = drive.files().get_media(fileId=source_file_id)
    buffer = io.BytesIO()
    downloader = MediaIoBaseDownload(buffer, request)

    try:
        done = False
        while not done:
            _, done = downloader.next_chunk()
    except HttpError as exc:
        status_code = (
            exc.resp.status
            if getattr(exc, "resp", None) and getattr(exc.resp, "status", None)
            else status.HTTP_502_BAD_GATEWAY
        )
        raise HTTPException(
            status_code=status_code,
            detail="Falha ao buscar arquivo no Google Drive.",
        ) from exc

    return buffer.getvalue(), photo["mime_type"], photo["name"]
