from unittest.mock import patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


@patch("app.routers.media.download_photo_bytes")
def test_media_proxy_returns_inline_image(mock_download_photo_bytes):
    mock_download_photo_bytes.return_value = (b"fake-image", "image/jpeg", "foto.jpg")

    response = client.get(
        "/api/v1/media/albums/04-02-2026/photos/photo-1",
        headers={"Origin": "http://localhost:3000"},
    )

    assert response.status_code == 200
    assert response.content == b"fake-image"
    assert response.headers["content-type"] == "image/jpeg"
    assert 'inline; filename="foto.jpg"' == response.headers["content-disposition"]
    assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
    assert response.headers["cross-origin-resource-policy"] == "cross-origin"


@patch("app.routers.media.download_photo_bytes")
def test_media_proxy_can_force_download(mock_download_photo_bytes):
    mock_download_photo_bytes.return_value = (b"fake-image", "image/jpeg", "foto.jpg")

    response = client.get(
        "/api/v1/media/albums/04-02-2026/photos/photo-1?download=true"
    )

    assert response.status_code == 200
    assert (
        response.headers["content-disposition"]
        == 'attachment; filename="foto.jpg"'
    )


@patch("app.routers.media.download_photo_bytes")
def test_media_proxy_returns_not_found_from_service(mock_download_photo_bytes):
    mock_download_photo_bytes.side_effect = HTTPException(
        status_code=404,
        detail="Foto nao encontrada.",
    )

    response = client.get("/api/v1/media/albums/04-02-2026/photos/inexistente")

    assert response.status_code == 404
    assert response.json()["detail"] == "Foto nao encontrada."


@patch("app.routers.media.download_photo_bytes")
def test_media_proxy_returns_validation_error_from_service(
    mock_download_photo_bytes,
):
    mock_download_photo_bytes.side_effect = HTTPException(
        status_code=422,
        detail="Foto sem referencia de origem no Drive.",
    )

    response = client.get("/api/v1/media/albums/04-02-2026/photos/sem-source-id")

    assert response.status_code == 422
    assert response.json()["detail"] == "Foto sem referencia de origem no Drive."
