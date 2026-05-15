from __future__ import annotations

import sys

from desktop_app.agent_controller import MISSING_PYSIDE6_MESSAGE


def main():
    try:
        from PySide6.QtWidgets import QApplication
    except ImportError:
        print(MISSING_PYSIDE6_MESSAGE)
        return 1

    from desktop_app.main_window import MainWindow

    app = QApplication(sys.argv)
    window = MainWindow()
    app.aboutToQuit.connect(window.controller.stop)
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())

