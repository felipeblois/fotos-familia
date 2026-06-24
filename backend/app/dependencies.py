"""Dependencias do FastAPI para autenticacao e inicializacao Firebase."""

from __future__ import annotations

import os
from functools import lru_cache
from typing import Optional

import structlog
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import settings

logger = structlog.get_logger()

_bearer_scheme = HTTPBearer(auto_error=True)
_bearer_optional = HTTPBearer(auto_error=False)


@lru_cache(maxsize=1)
def get_firebase_app():
    import firebase_admin
    from firebase_admin import credentials

    if firebase_admin._apps:
      return firebase_admin.get_app()

    sa_path = settings.FIREBASE_SERVICE_ACCOUNT_PATH
    if sa_path and os.path.exists(sa_path):
        cred = credentials.Certificate(sa_path)
        logger.info("firebase_init", method="service_account")
    else:
        cred = credentials.ApplicationDefault()
        logger.info("firebase_init", method="application_default")

    return firebase_admin.initialize_app(
        cred,
        {"projectId": settings.FIREBASE_PROJECT_ID},
    )


async def verify_firebase_token(
    http_credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
) -> dict:
    from firebase_admin import auth

    try:
        app = get_firebase_app()
        return auth.verify_id_token(
            http_credentials.credentials,
            app=app,
            check_revoked=True,
        )
    except Exception as exc:
        logger.warning("invalid_firebase_token", error_type=type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticacao invalido ou expirado.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


async def verify_admin_token(
    token_data: dict = Depends(verify_firebase_token),
) -> dict:
    uid: str = token_data.get("uid", "")
    sign_in_provider: str = (
        token_data.get("firebase", {}).get("sign_in_provider", "")
    )

    if sign_in_provider == "anonymous" or not uid:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Area administrativa requer autenticacao Google.",
        )

    if uid not in settings.ADMIN_UID_WHITELIST:
        logger.warning("unauthorized_admin_attempt", uid_prefix=uid[:8])
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seu usuario nao possui privilegios administrativos.",
        )

    return token_data


async def get_optional_token(
    http_credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        _bearer_optional
    ),
) -> Optional[dict]:
    if http_credentials is None:
        return None

    try:
        from firebase_admin import auth

        app = get_firebase_app()
        return auth.verify_id_token(http_credentials.credentials, app=app)
    except Exception:
        return None
