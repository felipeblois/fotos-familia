"""
NEVIIM — Testes do endpoint /health (CO01).

Cobre:
- Status 200 em condições normais
- Estrutura correta da resposta
- Campos obrigatórios presentes
- Timestamp em formato ISO-8601 UTC
"""

import re
from datetime import datetime

import pytest


class TestHealthEndpoint:
    """Suite de testes para GET /health."""

    def test_health_returns_200(self, client):
        """CO01: /health deve retornar HTTP 200."""
        response = client.get("/health")
        assert response.status_code == 200

    def test_health_response_structure(self, client):
        """Resposta deve conter todos os campos obrigatórios."""
        response = client.get("/health")
        data = response.json()

        assert "status" in data
        assert "version" in data
        assert "environment" in data
        assert "timestamp" in data

    def test_health_status_is_ok(self, client):
        """Status deve ser 'ok' quando o serviço está operacional."""
        response = client.get("/health")
        assert response.json()["status"] == "ok"

    def test_health_environment_is_test(self, client):
        """ENVIRONMENT deve refletir o valor configurado (test no CI)."""
        response = client.get("/health")
        assert response.json()["environment"] == "test"

    def test_health_version_format(self, client):
        """Versão deve seguir semver (ex: 0.1.0)."""
        response = client.get("/health")
        version = response.json()["version"]
        assert re.match(r"^\d+\.\d+\.\d+", version), f"Versão inválida: {version}"

    def test_health_timestamp_is_iso8601(self, client):
        """Timestamp deve ser ISO-8601 com timezone UTC."""
        response = client.get("/health")
        timestamp_str = response.json()["timestamp"]

        # Tenta parsear — levanta ValueError se formato inválido
        ts = datetime.fromisoformat(timestamp_str)
        assert ts.tzinfo is not None, "Timestamp deve ter timezone (UTC)"

    def test_health_content_type_is_json(self, client):
        """Content-Type deve ser application/json."""
        response = client.get("/health")
        assert "application/json" in response.headers["content-type"]

    def test_health_security_headers_present(self, client):
        """HE03: Headers de segurança devem estar presentes."""
        response = client.get("/health")
        headers = response.headers

        assert "x-frame-options" in headers
        assert "x-content-type-options" in headers
        assert "content-security-policy" in headers
        assert headers["x-frame-options"] == "DENY"
        assert headers["x-content-type-options"] == "nosniff"

    def test_health_no_server_header(self, client):
        """HE05: Header 'Server' não deve ser exposto."""
        response = client.get("/health")
        assert "server" not in response.headers

    def test_health_request_id_header(self, client):
        """AU02: X-Request-ID deve estar presente para rastreabilidade."""
        response = client.get("/health")
        assert "x-request-id" in response.headers
        # Deve ser UUID válido
        request_id = response.headers["x-request-id"]
        assert len(request_id) == 36  # UUID4 format
