"""Script local para indexar uma pasta do Google Drive no Firestore."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from functions.indexer import (  # noqa: E402
    _get_folder_metadata,
    _list_album_folders,
    get_drive_service,
    index_drive_folder,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Indexa fotos do Google Drive no Firestore do projeto Neviim.",
    )
    parser.add_argument(
        "--folder-id",
        default=os.getenv("DRIVE_FOLDER_ID", ""),
        help="ID da pasta do Google Drive.",
    )
    parser.add_argument(
        "--folder-name",
        default="",
        help=(
            "Nome de uma subpasta direta dentro de --folder-id para indexar "
            "como raiz. Exemplo: Galeria."
        ),
    )
    parser.add_argument(
        "--credentials",
        default=os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH", ""),
        help="Caminho do service account JSON.",
    )
    parser.add_argument(
        "--notify",
        action="store_true",
        help="Envia notificacao FCM apos indexar novas fotos.",
    )
    parser.add_argument(
        "--include-subfolders",
        action="store_true",
        help="Tambem indexa subpastas da pasta raiz como albuns separados.",
    )
    parser.add_argument(
        "--prune-missing-albums",
        action="store_true",
        help=(
            "Marca como removidos os albuns antigos e fotos antigas que nao "
            "foram encontradas na indexacao atual."
        ),
    )
    parser.add_argument(
        "--max-photo-file-size-mb",
        type=int,
        default=None,
        help="Limite maximo de tamanho por foto. Padrao: 50 MB.",
    )
    return parser.parse_args()


def resolve_folder_id_by_name(
    parent_folder_id: str,
    credentials_path: str,
    folder_name: str,
) -> str:
    expected_name = folder_name.strip().casefold()
    if not expected_name:
        return parent_folder_id

    drive_service = get_drive_service(credentials_path)
    parent_meta = _get_folder_metadata(drive_service, parent_folder_id)
    parent_name = str(parent_meta.get("name", "")).strip().casefold()
    if parent_name == expected_name:
        return parent_folder_id

    matches = [
        folder
        for folder in _list_album_folders(drive_service, parent_folder_id)
        if str(folder.get("name", "")).strip().casefold() == expected_name
    ]

    if not matches:
        available = ", ".join(
            folder.get("name", "sem-nome")
            for folder in _list_album_folders(drive_service, parent_folder_id)
        )
        raise SystemExit(
            f"Subpasta '{folder_name}' nao encontrada dentro de {parent_folder_id}. "
            f"Subpastas visiveis: {available or 'nenhuma'}."
        )

    if len(matches) > 1:
        ids = ", ".join(folder.get("id", "sem-id") for folder in matches)
        raise SystemExit(
            f"Mais de uma subpasta chamada '{folder_name}' foi encontrada. "
            f"Use --folder-id diretamente com um destes IDs: {ids}."
        )

    folder_id = str(matches[0].get("id", ""))
    if not folder_id:
        raise SystemExit(f"Subpasta '{folder_name}' encontrada sem ID valido.")

    print(
        f"Indexando subpasta '{matches[0].get('name')}' "
        f"com folder_id={folder_id}"
    )
    return folder_id


def main() -> int:
    load_dotenv()
    args = parse_args()

    if not args.folder_id:
        raise SystemExit("Informe DRIVE_FOLDER_ID ou use --folder-id.")

    if args.max_photo_file_size_mb:
        os.environ["MAX_PHOTO_FILE_SIZE_MB"] = str(args.max_photo_file_size_mb)

    if not args.credentials:
        raise SystemExit(
            "Informe FIREBASE_SERVICE_ACCOUNT_PATH ou use --credentials.",
        )

    credentials_path = Path(args.credentials)
    if not credentials_path.exists():
        raise SystemExit(f"Arquivo de credenciais nao encontrado: {credentials_path}")

    folder_id = resolve_folder_id_by_name(
        args.folder_id,
        str(credentials_path),
        args.folder_name,
    )

    summary = index_drive_folder(
        folder_id,
        str(credentials_path),
        send_notifications=args.notify,
        include_subfolders=args.include_subfolders,
        prune_missing_albums=args.prune_missing_albums,
    )
    print(summary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
