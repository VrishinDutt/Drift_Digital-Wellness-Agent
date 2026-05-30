import unittest
from unittest.mock import patch

from telemetry import windows_tracker


class WindowsTrackerTests(unittest.TestCase):

    def test_missing_dependencies_return_non_invasive_unknown_snapshot(self):
        with patch.object(windows_tracker, "psutil", None), patch.object(
            windows_tracker,
            "win32api",
            None,
        ), patch.object(windows_tracker, "win32gui", None), patch.object(
            windows_tracker,
            "win32process",
            None,
        ):
            snapshot = windows_tracker.get_active_window_snapshot()

        self.assertEqual(snapshot["active_app"], "Unknown")
        self.assertEqual(snapshot["window_title"], "Unknown")
        self.assertEqual(
            snapshot["permission_status"],
            "missing_windows_dependency",
        )

    def test_idle_seconds_handles_windows_tick_wrap(self):
        class FakeWin32Api:
            @staticmethod
            def GetLastInputInfo():
                return (2 ** 32) - 500

            @staticmethod
            def GetTickCount():
                return 500

        with patch.object(windows_tracker, "win32api", FakeWin32Api):
            self.assertEqual(windows_tracker.get_idle_seconds(), 1.0)


if __name__ == "__main__":
    unittest.main()
