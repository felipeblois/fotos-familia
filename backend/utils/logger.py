import json
import logging
import traceback
from datetime import datetime, timezone
from typing import Any


class StructJSONFormatter(logging.Formatter):
    """Formatador JSON simples para logs locais e Cloud Logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_payload: dict[str, Any] = {
            "severity": record.levelname,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "message": record.getMessage(),
            "logger": record.name,
            "file": record.filename,
            "line": record.lineno,
        }

        if record.exc_info:
            log_payload["exception"] = "".join(
                traceback.format_exception(*record.exc_info)
            )

        if hasattr(record, "extra_fields"):
            log_payload.update(record.extra_fields)

        return json.dumps(log_payload)


def setup_cloud_logger(name: str = "app_neviim") -> logging.Logger:
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    if not logger.handlers:
        handler = logging.StreamHandler()
        handler.setFormatter(StructJSONFormatter())
        logger.addHandler(handler)

    logger.propagate = False
    return logger
