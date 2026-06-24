from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def mock_invalid_admin_dependency():
    raise HTTPException(
        status_code=403,
        detail="Seu usuario nao possui privilegios administrativos.",
    )


@pytest.fixture
def override_admin_auth():
    from app.dependencies import verify_admin_token

    app.dependency_overrides[verify_admin_token] = mock_invalid_admin_dependency
    yield
    app.dependency_overrides.pop(verify_admin_token, None)


def test_admin_route_recebe_403_para_nao_admins(override_admin_auth):
    response = client.delete("/api/v1/admin/albums/2024-05-10/photos/fake123")
    assert response.status_code == 403
    assert "privilegios administrativos" in response.json().get("detail", "")


@patch("app.routers.admin.list_albums")
def test_admin_list_albums_retorna_dados(mock_list_albums):
    from app.dependencies import verify_admin_token

    app.dependency_overrides[verify_admin_token] = lambda: {"uid": "test-admin"}
    mock_list_albums.return_value = [
        {
            "id": "2024-05-10",
            "title": "2024-05-10",
            "photo_count": 2,
            "cover_url": "",
            "created_at": "2024-05-10",
            "last_indexed_at": "2024-05-10T10:00:00Z",
            "is_deleted": False,
        }
    ]

    response = client.get("/api/v1/admin/albums")

    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["albums"]) == 1


@patch("app.routers.admin.soft_delete_photo")
def test_admin_delete_photo_sucesso(mock_delete_photo):
    from app.dependencies import verify_admin_token

    app.dependency_overrides[verify_admin_token] = lambda: {"uid": "test-admin"}
    mock_delete_photo.return_value = True

    response = client.delete("/api/v1/admin/albums/2024-05-10/photos/foto-1")

    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["data"]["deleted"] is True


@patch("app.routers.admin.list_audit_logs")
def test_admin_list_audit_logs_retorna_dados(mock_list_audit_logs):
    from app.dependencies import verify_admin_token

    app.dependency_overrides[verify_admin_token] = lambda: {"uid": "test-admin"}
    mock_list_audit_logs.return_value = [
        {
            "id": "log-1",
            "action": "photo.soft_delete",
            "admin_uid": "test-admin",
            "album_id": "28-01-2026",
            "photo_id": "foto-1",
            "created_at": "2026-04-17T00:00:00+00:00",
        }
    ]

    response = client.get("/api/v1/admin/audit-logs")

    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json()["success"] is True
    assert len(response.json()["data"]["logs"]) == 1
