from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest

from functions.indexer import extract_date_from_file, index_drive_folder


def test_extract_date_from_file_valid_exif():
    file_meta = {
        "imageMediaMetadata": {
            "time": "2024:05:15 10:30:00",
        }
    }
    assert extract_date_from_file(file_meta) == "2024-05-15"


def test_extract_date_fallback_to_created_time():
    file_meta = {
        "createdTime": "2023-12-25T14:30:00.000Z",
    }
    assert extract_date_from_file(file_meta) == "2023-12-25"


def test_extract_date_fallback_to_now():
    file_meta = {}
    hoje = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    assert extract_date_from_file(file_meta) == hoje


@pytest.fixture
def mock_drive_service():
    with patch("functions.indexer.get_drive_service") as mock_ds:
        yield mock_ds


@pytest.fixture
def mock_firestore_client():
    with patch("functions.indexer.get_firestore_client") as mock_fs:
        yield mock_fs


def test_indexer_run_root_folder_as_album(mock_drive_service, mock_firestore_client):
    mock_drive = MagicMock()
    mock_drive_service.return_value = mock_drive

    mock_drive.files().get.return_value.execute.return_value = {
        "id": "test_folder_id",
        "name": "Galeria",
        "mimeType": "application/vnd.google-apps.folder",
        "createdTime": "2024-01-01T00:00:00Z",
    }

    mock_list = mock_drive.files().list
    mock_list.side_effect = [
        MagicMock(
            execute=MagicMock(
                return_value={
                    "files": [
                        {
                            "id": "file_jpg_1",
                            "name": "missa.jpg",
                            "mimeType": "image/jpeg",
                            "createdTime": "2024-01-01T10:00:00Z",
                            "webContentLink": "http://download/1",
                            "webViewLink": "http://view/1",
                            "imageMediaMetadata": {"width": 100, "height": 80},
                        },
                        {
                            "id": "file_png_2",
                            "name": "altar.png",
                            "mimeType": "image/png",
                            "createdTime": "2024-01-01T14:30:00.000Z",
                            "webContentLink": "http://download/2",
                            "webViewLink": "http://view/2",
                            "imageMediaMetadata": {"width": 100, "height": 80},
                        },
                    ],
                    "nextPageToken": None,
                }
            )
        ),
    ]

    mock_db = MagicMock()
    mock_firestore_client.return_value = mock_db
    mock_batch = MagicMock()
    mock_db.batch.return_value = mock_batch

    mock_album_ref = MagicMock()
    mock_db.collection().document.return_value = mock_album_ref
    mock_photo_ref = MagicMock()
    mock_album_ref.collection().document.return_value = mock_photo_ref

    summary = index_drive_folder("test_folder_id", "fake_path.json")

    assert summary["processed"] == 2
    assert summary["inserted"] == 2
    assert summary["skipped"] == 0
    assert mock_batch.set.call_count == 3
    assert mock_batch.commit.call_count == 1

    first_q = mock_list.call_args_list[0].kwargs["q"]
    assert "'test_folder_id' in parents" in first_q
    assert "mimeType != 'application/vnd.google-apps.folder'" in first_q
