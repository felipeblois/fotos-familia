"""
NEVIIM API - Configuracao via variaveis de ambiente.

Usa pydantic-settings para validar e tipificar todas as variaveis.
Em desenvolvimento: le do arquivo .env via python-dotenv.
Em producao: le das variaveis de ambiente ou secrets montados.
"""

from typing import List

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    ENVIRONMENT: str = "development"
    APP_VERSION: str = "0.1.0"
    APP_PORT: int = 8000
    LOG_LEVEL: str = "INFO"

    FIREBASE_PROJECT_ID: str = "neviim-app-local"
    FIREBASE_SERVICE_ACCOUNT_PATH: str = ""

    GCP_PROJECT_ID: str = "neviim-app-local"
    DRIVE_FOLDER_ID: str = "placeholder-drive-folder-id"

    ADMIN_UID_WHITELIST: List[str] = []
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
    ]
    RATE_LIMIT_PER_MINUTE: int = 60

    TERMS_VERSION: str = "1.0.0"
    LGPD_CONTACT_EMAIL: str = "paroquia@example.com"
    DPO_NAME: str = "Responsavel da Paroquia"

    FCM_SENDER_ID: str = ""

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def validate_origins(cls, v: object) -> List[str]:
        if isinstance(v, list):
            return [str(origin).strip() for origin in v if str(origin).strip()]
        return v  # type: ignore[return-value]

    @field_validator("ADMIN_UID_WHITELIST", mode="before")
    @classmethod
    def validate_admin_uids(cls, v: object) -> List[str]:
        if isinstance(v, list):
            return [str(uid).strip() for uid in v if str(uid).strip()]
        return v  # type: ignore[return-value]

    @field_validator("ENVIRONMENT")
    @classmethod
    def validate_environment(cls, v: str) -> str:
        allowed = {"development", "production", "test"}
        if v not in allowed:
            raise ValueError(f"ENVIRONMENT deve ser um de: {allowed}")
        return v

    @field_validator("LOG_LEVEL")
    @classmethod
    def validate_log_level(cls, v: str) -> str:
        allowed = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        value = v.upper()
        if value not in allowed:
            raise ValueError(f"LOG_LEVEL deve ser um de: {allowed}")
        return value

    @model_validator(mode="after")
    def validate_production_requirements(self) -> "Settings":
        if self.ENVIRONMENT == "production":
            if not self.FIREBASE_SERVICE_ACCOUNT_PATH:
                raise ValueError(
                    "FIREBASE_SERVICE_ACCOUNT_PATH nao pode ser vazio em producao"
                )
            if (
                not self.DRIVE_FOLDER_ID
                or self.DRIVE_FOLDER_ID == "placeholder-drive-folder-id"
            ):
                raise ValueError(
                    "DRIVE_FOLDER_ID deve apontar para a pasta real em producao"
                )
            if not self.ADMIN_UID_WHITELIST:
                raise ValueError(
                    "ADMIN_UID_WHITELIST nao pode ser vazia em producao"
                )
            if not self.ALLOWED_ORIGINS:
                raise ValueError("ALLOWED_ORIGINS nao pode ser vazio em producao")
        return self


settings = Settings()
