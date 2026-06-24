"""Envio de notificacoes FCM para novas galerias."""

from __future__ import annotations

import logging

import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)


def get_firebase_app(service_account_path: str | None = None):
    """Retorna a app do Firebase Admin, inicializando apenas quando necessario."""
    try:
      return firebase_admin.get_app()
    except ValueError:
      if service_account_path:
          return firebase_admin.initialize_app(
              credentials.Certificate(service_account_path)
          )
      return firebase_admin.initialize_app()


def notify_new_photos(
    date_indexed: str,
    count: int,
    *,
    topic: str = "novas-fotos",
    service_account_path: str | None = None,
) -> bool:
    """Dispara uma notificacao simples para o topico padrao do app."""
    if count <= 0:
        return False

    get_firebase_app(service_account_path)

    message = messaging.Message(
        notification=messaging.Notification(
            title="Novas fotos disponiveis",
            body=(
                f"Foram adicionadas {count} foto(s) da galeria de {date_indexed}."
            ),
        ),
        topic=topic,
    )

    try:
        response = messaging.send(message)
        logger.info("FCM disparado com sucesso. Message ID: %s", response)
        return True
    except Exception as exc:  # pragma: no cover - rede externa
        logger.error("Falha ao enviar push FCM: %s", exc)
        return False
