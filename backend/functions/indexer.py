"""Indexacao de fotos do Google Drive para o Firestore."""

from __future__ import annotations

import datetime as dt
import os
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore
from google.oauth2 import service_account
from googleapiclient.discovery import build

from functions.notifier import notify_new_photos
from utils.logger import setup_cloud_logger

logger = setup_cloud_logger(__name__)

ALLOWED_MIME_TYPES = ["image/jpeg", "image/png", "image/webp"]
GOOGLE_FOLDER_MIME_TYPE = "application/vnd.google-apps.folder"
DEFAULT_MAX_PHOTO_FILE_SIZE_MB = 50
DEFAULT_ROOT_ALBUM_TITLE = "Galeria"


def get_max_file_size_bytes() -> int:
    return (
        int(os.getenv("MAX_PHOTO_FILE_SIZE_MB", str(DEFAULT_MAX_PHOTO_FILE_SIZE_MB)))
        * 1024
        * 1024
    )


def get_drive_service(creds_path: str):
    creds = service_account.Credentials.from_service_account_file(
        creds_path,
        scopes=["https://www.googleapis.com/auth/drive.readonly"],
    )
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def get_firestore_client(creds_path: str):
    try:
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate(creds_path)
        firebase_admin.initialize_app(
            cred,
            {"projectId": cred.project_id},
        )
    return firestore.client()


def extract_date_from_file(file_meta: dict[str, Any]) -> str:
    exif_time = file_meta.get("imageMediaMetadata", {}).get("time")
    if exif_time and len(exif_time) >= 10:
        parts = exif_time.split(" ")[0].split(":")
        if len(parts) == 3:
            return f"{parts[0]}-{parts[1]}-{parts[2]}"

    created_time = file_meta.get("createdTime")
    if created_time and len(created_time) >= 10:
        return created_time[:10]

    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d")


def _list_drive_items(
    drive_service,
    query: str,
    *,
    page_size: int = 100,
) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    page_token = None

    while True:
        response = (
            drive_service.files()
            .list(
                q=query,
                spaces="drive",
                fields=(
                    "nextPageToken, files("
                    "id, name, mimeType, size, createdTime, imageMediaMetadata, "
                    "thumbnailLink, webContentLink, webViewLink)"
                ),
                pageToken=page_token,
                pageSize=page_size,
            )
            .execute()
        )

        results.extend(response.get("files", []))
        page_token = response.get("nextPageToken")
        if not page_token:
            return results


def _list_album_folders(drive_service, root_folder_id: str) -> list[dict[str, Any]]:
    query = (
        f"'{root_folder_id}' in parents and trashed=false and "
        f"mimeType='{GOOGLE_FOLDER_MIME_TYPE}'"
    )
    return _list_drive_items(drive_service, query)


def _get_folder_metadata(drive_service, folder_id: str) -> dict[str, Any]:
    return (
        drive_service.files()
        .get(
            fileId=folder_id,
            fields="id, name, mimeType, createdTime, webViewLink",
        )
        .execute()
    )


def _list_album_files(drive_service, folder_id: str) -> list[dict[str, Any]]:
    query = (
        f"'{folder_id}' in parents and trashed=false and "
        f"mimeType != '{GOOGLE_FOLDER_MIME_TYPE}'"
    )
    return _list_drive_items(drive_service, query)


def _safe_album_id(value: str) -> str:
    album_id = value.strip().replace("/", "-")
    return album_id or DEFAULT_ROOT_ALBUM_TITLE


def _build_photo_document(
    file_meta: dict[str, Any],
    album_id: str,
) -> dict[str, Any]:
    created_at = file_meta.get("createdTime") or dt.datetime.now(
        dt.timezone.utc
    ).isoformat()
    image_url = (
        file_meta.get("thumbnailLink")
        or file_meta.get("webContentLink")
        or file_meta.get("webViewLink")
        or ""
    )
    return {
        "id": file_meta.get("id"),
        "source_file_id": file_meta.get("id"),
        "name": file_meta.get("name"),
        "album_id": album_id,
        "created_at": created_at,
        "download_url": file_meta.get("webContentLink", ""),
        "view_url": file_meta.get("webViewLink", ""),
        "thumbnail_url": image_url,
        "mime_type": file_meta.get("mimeType"),
        "width": file_meta.get("imageMediaMetadata", {}).get("width"),
        "height": file_meta.get("imageMediaMetadata", {}).get("height"),
        "is_deleted": False,
        "indexed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    }


def _album_id_from_folder(folder_meta: dict[str, Any]) -> str:
    return _safe_album_id(
        folder_meta.get("name") or folder_meta.get("id") or extract_date_from_file(
            folder_meta
        )
    )


def _soft_delete_missing_albums(db, indexed_album_ids: set[str]) -> int:
    if not indexed_album_ids:
        logger.warning("Nenhum album indexado. Limpeza de albuns antigos ignorada.")
        return 0

    pruned = 0
    batch = db.batch()
    batch_count = 0
    now = dt.datetime.now(dt.timezone.utc).isoformat()

    for album_doc in db.collection("albums").stream():
        if album_doc.id in indexed_album_ids:
            continue

        album_data = album_doc.to_dict() or {}
        if album_data.get("is_deleted", False):
            continue

        batch.update(
            album_doc.reference,
            {
                "is_deleted": True,
                "last_indexed_at": now,
            },
        )
        batch_count += 1
        pruned += 1

        if batch_count >= 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    return pruned


def _soft_delete_missing_photos(
    db,
    album_id: str,
    indexed_photo_ids: set[str],
) -> int:
    if not indexed_photo_ids:
        return 0

    pruned = 0
    batch = db.batch()
    batch_count = 0
    now = dt.datetime.now(dt.timezone.utc).isoformat()

    photos_ref = db.collection("albums").document(album_id).collection("photos")
    for photo_doc in photos_ref.stream():
        if photo_doc.id in indexed_photo_ids:
            continue

        photo_data = photo_doc.to_dict() or {}
        if photo_data.get("is_deleted", False):
            continue

        batch.update(
            photo_doc.reference,
            {
                "is_deleted": True,
                "indexed_at": now,
            },
        )
        batch_count += 1
        pruned += 1

        if batch_count >= 400:
            batch.commit()
            batch = db.batch()
            batch_count = 0

    if batch_count > 0:
        batch.commit()

    return pruned


def index_drive_folder(
    folder_id: str,
    gcp_creds_path: str,
    *,
    send_notifications: bool = False,
    include_subfolders: bool = False,
    prune_missing_albums: bool = False,
) -> dict[str, int]:
    logger.info("Iniciando indexacao da pasta Drive: %s", folder_id)

    drive_service = get_drive_service(gcp_creds_path)
    db = get_firestore_client(gcp_creds_path)
    root_album = _get_folder_metadata(drive_service, folder_id)
    root_album["name"] = root_album.get("name") or DEFAULT_ROOT_ALBUM_TITLE
    album_folders = [root_album]
    if include_subfolders:
        album_folders.extend(_list_album_folders(drive_service, folder_id))

    processed = 0
    inserted = 0
    skipped = 0
    pruned = 0
    pruned_photos = 0
    indexed_album_ids: set[str] = set()
    batch = db.batch()
    batch_count = 0

    for album_folder in album_folders:
        album_source_id = album_folder.get("id", "")
        album_id = _album_id_from_folder(album_folder)
        album_title = album_folder.get("name", album_id)
        album_files = _list_album_files(drive_service, album_source_id)
        valid_count = 0
        album_cover = ""
        indexed_photo_ids: set[str] = set()

        for file_meta in album_files:
            processed += 1
            file_id = file_meta.get("id")
            mime_type = file_meta.get("mimeType")

            if not file_id:
                skipped += 1
                logger.warning("Arquivo rejeitado sem ID valido: %s", file_meta)
                continue

            if mime_type not in ALLOWED_MIME_TYPES:
                skipped += 1
                logger.warning(
                    "Arquivo rejeitado por MIME invalido: id=%s nome=%s mime=%s",
                    file_id,
                    file_meta.get("name"),
                    mime_type,
                )
                continue

            raw_size = file_meta.get("size")
            max_file_size_bytes = get_max_file_size_bytes()
            if raw_size and int(raw_size) > max_file_size_bytes:
                skipped += 1
                logger.warning(
                    (
                        "Arquivo rejeitado por tamanho excedido: "
                        "id=%s nome=%s tamanho_mb=%.2f limite_mb=%.2f"
                    ),
                    file_id,
                    file_meta.get("name"),
                    int(raw_size) / 1024 / 1024,
                    max_file_size_bytes / 1024 / 1024,
                )
                continue

            doc_data = _build_photo_document(file_meta, album_id)
            if not album_cover:
                album_cover = doc_data["thumbnail_url"]

            album_ref = db.collection("albums").document(album_id)
            photo_ref = album_ref.collection("photos").document(file_id)
            batch.set(photo_ref, doc_data, merge=True)
            batch_count += 1

            valid_count += 1
            inserted += 1
            indexed_photo_ids.add(file_id)

            if batch_count >= 400:
                batch.commit()
                batch = db.batch()
                batch_count = 0

        if valid_count > 0:
            album_ref = db.collection("albums").document(album_id)
            indexed_album_ids.add(album_id)
            batch.set(
                album_ref,
                {
                    "title": album_title,
                    "source_folder_id": album_source_id,
                    "cover_url": album_cover,
                    "photo_count": valid_count,
                    "created_at": album_folder.get("createdTime", album_id),
                    "last_indexed_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                    "is_deleted": False,
                },
                merge=True,
            )
            batch_count += 1

            if batch_count >= 400:
                batch.commit()
                batch = db.batch()
                batch_count = 0

            if prune_missing_albums:
                if batch_count > 0:
                    batch.commit()
                    batch = db.batch()
                    batch_count = 0
                pruned_photos += _soft_delete_missing_photos(
                    db,
                    album_id,
                    indexed_photo_ids,
                )

    if batch_count > 0:
        batch.commit()

    if prune_missing_albums:
        pruned = _soft_delete_missing_albums(db, indexed_album_ids)

    logger.info(
        (
            "Indexacao concluida. Processadas=%s Inseridas=%s Ignoradas=%s "
            "Albuns removidos=%s Fotos removidas=%s"
        ),
        processed,
        inserted,
        skipped,
        pruned,
        pruned_photos,
    )

    if send_notifications and inserted > 0:
        notify_new_photos(
            dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d"),
            inserted,
            service_account_path=gcp_creds_path,
        )

    return {
        "processed": processed,
        "inserted": inserted,
        "skipped": skipped,
        "pruned": pruned,
        "pruned_photos": pruned_photos,
    }
