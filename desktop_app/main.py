from __future__ import annotations

import multiprocessing
import os
import sys

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from desktop_app.agent_controller import MISSING_PYSIDE6_MESSAGE
from telemetry.diagnostics import (
    DIAGNOSTIC_LOG_FILE,
    install_crash_handlers,
    log_exception,
)


def main():
    multiprocessing.freeze_support()
    install_crash_handlers()

    try:
        from PySide6.QtWidgets import QApplication
    except ImportError:
        print(MISSING_PYSIDE6_MESSAGE)
        return 1

    try:
        from desktop_app.main_window import MainWindow

        app = QApplication.instance() or QApplication(sys.argv)
        app.setApplicationName("Intentional")
        app.setOrganizationName("Drift")

        window = MainWindow()
        app.aboutToQuit.connect(window.controller.stop)
        window.show()
        return app.exec()
    except Exception as exc:
        log_exception(
            "desktop_app_startup_failed",
            exc,
            logger_name="desktop"
        )
        print(
            "Intentional failed to start. "
            f"Diagnostics were written to: {DIAGNOSTIC_LOG_FILE}",
            file=sys.stderr
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
