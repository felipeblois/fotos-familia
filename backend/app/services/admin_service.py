"""Servicos de administracao para galerias e auditoria."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from firebase_admin import firestore


def _serialize_timestamp(value: Any) -> str:
    if value is None:
        return ""
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)


def list_albums() -> list[dict[str, Any]]:
    db = firestore.client()
    docs = (
        db.collection("albums")
        .where("is_deleted", "==", False)
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .stream()
    )

    albums: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        albums.append(
            {
                "id": doc.id,
                "title": data.get("title", doc.id),
                "cover_url": data.get("cover_url", ""),
                "photo_count": data.get("photo_count", 0),
                "created_at": _serialize_timestamp(data.get("created_at")),
                "last_indexed_at": _serialize_timestamp(data.get("last_indexed_at")),
                "is_deleted": data.get("is_deleted", False),
            }
        )
    return albums


def list_album_photos(album_id: str) -> list[dict[str, Any]]:
    db = firestore.client()
    docs = (
        db.collection("albums")
        .document(album_id)
        .collection("photos")
        .where("is_deleted", "==", False)
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .stream()
    )

    photos: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        photos.append(
            {
                "id": doc.id,
                "album_id": data.get("album_id", album_id),
                "name": data.get("name", ""),
                "created_at": _serialize_timestamp(data.get("created_at")),
                "download_url": data.get("download_url", ""),
                "view_url": data.get("view_url", ""),
                "thumbnail_url": data.get("thumbnail_url", ""),
                "mime_type": data.get("mime_type", ""),
                "is_deleted": data.get("is_deleted", False),
                "indexed_at": _serialize_timestamp(data.get("indexed_at")),
            }
        )
    return photos


def soft_delete_photo(album_id: str, photo_id: str, admin_uid: str) -> bool:
    db = firestore.client()
    album_ref = db.collection("albums").document(album_id)
    photo_ref = album_ref.collection("photos").document(photo_id)
    photo_doc = photo_ref.get()

    if not photo_doc.exists:
        return False

    batch = db.batch()
    batch.update(photo_ref, {"is_deleted": True})

    album_data = album_ref.get().to_dict() or {}
    current_count = max(int(album_data.get("photo_count", 1)) - 1, 0)
    batch.set(
        album_ref,
        {
            "photo_count": current_count,
            "last_indexed_at": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )

    audit_ref = db.collection("audit_log").document()
    batch.set(
        audit_ref,
        {
            "action": "photo.soft_delete",
            "admin_uid": admin_uid,
            "album_id": album_id,
            "photo_id": photo_id,
            "timestamp": firestore.SERVER_TIMESTAMP,
            "created_at": datetime.now(timezone.utc).isoformat(),
        },
    )
    batch.commit()
    return True


def list_audit_logs(limit: int = 50) -> list[dict[str, Any]]:
    db = firestore.client()
    docs = (
        db.collection("audit_log")
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )

    logs: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        logs.append({"id": doc.id, **data})
    return logs
