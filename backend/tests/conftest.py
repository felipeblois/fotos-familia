"""
NEVIIM — Configuração base dos testes (pytest fixtures globais).

Estratégia:
- Variáveis de ambiente mockadas ANTES de importar a app (evita erro de validação)
- Firebase Admin SDK mockado (sem conexão real nos testes unitários)
- TestClient do FastAPI/httpx para testes HTTP
"""

import os

import pytest
from fastapi.testclient import TestClient

# ---------------------------------------------------------------------------
# IMPORTANTE: Configurar env vars ANTES de qualquer import da app
# Isso garante que pydantic-settings não falhe por variáveis faltando
# ---------------------------------------------------------------------------
os.environ.setdefault("ENVIRONMENT", "test")
os.environ.setdefault("FIREBASE_PROJECT_ID", "neviim-test-project")
os.environ.setdefault("DRIVE_FOLDER_ID", "test-drive-folder-id")
# pydantic-settings 2.10+ exige JSON array para campos List[str]
os.environ.setdefault("ADMIN_UID_WHITELIST", '["test-admin-uid-001"]')
os.environ.setdefault("ALLOWED_ORIGINS", '["http://localhost:3000", "http://localhost:8080"]')
os.environ.setdefault("LOG_LEVEL", "WARNING")  # Silencia logs nos testes


# ---------------------------------------------------------------------------
# Fixture: cliente HTTP para testes (sem server real, in-process)
# ---------------------------------------------------------------------------
@pytest.fixture(scope="session")
def client() -> TestClient:
    """
    Cliente de testes HTTP reutilizado em toda a sessão.
    Evita overhead de (re)inicialização da app para cada teste.
    """
    from app.main import app

    with TestClient(app, raise_server_exceptions=True) as c:
        yield c


# ---------------------------------------------------------------------------
# Fixture: mock do Firebase Admin (evita conexão real)
# ---------------------------------------------------------------------------
@pytest.fixture(autouse=True)
def mock_firebase(monkeypatch):
    """
    Mocka a inicialização do Firebase em TODOS os testes automaticamente.
    Evita que testes unitários tentem conectar ao Firebase real.
    """
    import unittest.mock as mock

    # Mock do firebase_admin para evitar inicialização real
    with mock.patch("app.dependencies.get_firebase_app") as mock_app:
        mock_app.return_value = mock.MagicMock()
        yield mock_app
