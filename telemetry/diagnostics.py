import logging
import sys
import threading
from logging.handlers import RotatingFileHandler

from core.paths import data_path
from telemetry.log_store import ensure_parent_dir

DIAGNOSTIC_LOG_FILE = data_path("diagnostics.log")
MAX_DIAGNOSTIC_LOG_BYTES = 256 * 1024
DIAGNOSTIC_BACKUP_COUNT = 3
LOGGER_NAME = "drift"

_configured = False
_original_excepthook = sys.excepthook
_original_threading_excepthook = getattr(threading, "excepthook", None)


def configure_diagnostics():
    global _configured

    logger = logging.getLogger(LOGGER_NAME)

    if _configured:
        return logger

    ensure_parent_dir(DIAGNOSTIC_LOG_FILE)
    handler = RotatingFileHandler(
        DIAGNOSTIC_LOG_FILE,
        maxBytes=MAX_DIAGNOSTIC_LOG_BYTES,
        backupCount=DIAGNOSTIC_BACKUP_COUNT,
        encoding="utf-8",
    )
    handler.setFormatter(logging.Formatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s"
    ))

    logger.setLevel(logging.INFO)
    logger.addHandler(handler)
    logger.propagate = False
    _configured = True

    return logger


def get_logger(name=None):
    base_logger = configure_diagnostics()

    if not name:
        return base_logger

    return logging.getLogger(f"{LOGGER_NAME}.{name}")


def log_exception(event, exc, logger_name=None):
    logger = get_logger(logger_name)
    logger.exception("%s: %s: %s", event, exc.__class__.__name__, exc)


def install_crash_handlers():
    configure_diagnostics()

    def excepthook(exc_type, exc, traceback):
        if issubclass(exc_type, KeyboardInterrupt):
            _original_excepthook(exc_type, exc, traceback)
            return

        logger = get_logger("crash")
        logger.error(
            "unhandled_exception",
            exc_info=(exc_type, exc, traceback),
        )
        _original_excepthook(exc_type, exc, traceback)

    def threading_excepthook(args):
        if issubclass(args.exc_type, KeyboardInterrupt):
            if _original_threading_excepthook:
                _original_threading_excepthook(args)
            return

        logger = get_logger("thread")
        logger.error(
            "unhandled_thread_exception",
            exc_info=(args.exc_type, args.exc_value, args.exc_traceback),
        )

        if _original_threading_excepthook:
            _original_threading_excepthook(args)

    sys.excepthook = excepthook

    if _original_threading_excepthook:
        threading.excepthook = threading_excepthook
