"""Inspeciona o que a service account enxerga no Google Drive."""

from __future__ import annotations

import argparse
import os
import sys
from collections import Counter
from pathlib import Path
from typing import Any

from dotenv import load_dotenv

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from functions.indexer import (  # noqa: E402
    ALLOWED_MIME_TYPES,
    _get_folder_metadata,
    _list_album_files,
    _list_album_folders,
    get_max_file_size_bytes,
    get_drive_service,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Mostra arquivos e subpastas visiveis para a service account.",
    )
    parser.add_argument(
        "--folder-id",
        default=os.getenv("DRIVE_FOLDER_ID", ""),
        help="ID da pasta do Google Drive.",
    )
    parser.add_argument(
        "--credentials",
        default=os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", ""),
        help="Caminho do service account JSON.",
    )
    parser.add_argument(
        "--include-subfolders",
        action="store_true",
        help="Tambem inspeciona subpastas diretas.",
    )
    return parser.parse_args()


def _size_mb(file_meta: dict[str, Any]) -> float:
    raw_size = file_meta.get("size")
    if not raw_size:
        return 0.0
    return int(raw_size) / 1024 / 1024


def _is_indexable(file_meta: dict[str, Any]) -> tuple[bool, str]:
    mime_type = file_meta.get("mimeType")
    if mime_type not in ALLOWED_MIME_TYPES:
        return False, f"mime nao suportado: {mime_type}"

    raw_size = file_meta.get("size")
    max_file_size_bytes = get_max_file_size_bytes()
    if raw_size and int(raw_size) > max_file_size_bytes:
        return False, (
            f"arquivo maior que {max_file_size_bytes / 1024 / 1024:.0f} MB"
        )

    return True, "ok"


def _print_folder(drive_service, folder_meta: dict[str, Any]) -> tuple[int, int]:
    folder_name = folder_meta.get("name", folder_meta.get("id", "sem-nome"))
    folder_id = folder_meta.get("id", "")
    files = _list_album_files(drive_service, folder_id)
    mime_counts = Counter(file_meta.get("mimeType", "sem-mime") for file_meta in files)
    indexable_count = 0

    print()
    print(f"Pasta: {folder_name}")
    print(f"ID: {folder_id}")
    print(f"Arquivos visiveis: {len(files)}")
    print(f"MIMEs: {dict(mime_counts)}")

    for file_meta in files:
        indexable, reason = _is_indexable(file_meta)
        if indexable:
            indexable_count += 1

        status = "INDEXA" if indexable else "IGNORA"
        print(
            "- "
            f"[{status}] {file_meta.get('name')} | "
            f"{file_meta.get('mimeType')} | "
            f"{_size_mb(file_meta):.2f} MB | "
            f"id={file_meta.get('id')} | {reason}"
        )

    print(f"Total que entraria no app: {indexable_count}")
    return len(files), indexable_count


def main() -> int:
    load_dotenv()
    args = parse_args()

    if not args.folder_id:
        raise SystemExit("Informe DRIVE_FOLDER_ID ou use --folder-id.")

    if not args.credentials:
        raise SystemExit(
            "Informe FIREBASE_SERVICE_ACCOUNT_PATH ou use --credentials.",
        )

    credentials_path = Path(args.credentials)
    if not credentials_path.exists():
        raise SystemExit(f"Arquivo de credenciais nao encontrado: {credentials_path}")

    drive_service = get_drive_service(str(credentials_path))
    root_folder = _get_folder_metadata(drive_service, args.folder_id)
    folders = [root_folder]
    if args.include_subfolders:
        subfolders = _list_album_folders(drive_service, args.folder_id)
        if subfolders:
            print("Subpastas diretas encontradas:")
            for folder in subfolders:
                print(f"- {folder.get('name')} | id={folder.get('id')}")
        folders.extend(subfolders)

    total_files = 0
    total_indexable = 0
    for folder_meta in folders:
        files, indexable = _print_folder(drive_service, folder_meta)
        total_files += files
        total_indexable += indexable

    print()
    print("Resumo")
    print(f"Pastas inspecionadas: {len(folders)}")
    print(f"Arquivos visiveis: {total_files}")
    print(f"Arquivos que entrariam no app: {total_indexable}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
