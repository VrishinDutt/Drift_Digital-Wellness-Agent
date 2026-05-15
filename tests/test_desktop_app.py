import unittest

from desktop_app.agent_controller import (
    AnalysisInFlightGuard,
    DemoSnapshotProvider,
)


class DesktopAppTests(unittest.TestCase):

    def test_demo_snapshot_provider_cycles_required_states(self):
        provider = DemoSnapshotProvider()

        observed = [
            (
                snapshot["reasoning"]["state"],
                snapshot["context"],
                snapshot["ccs"],
            )
            for snapshot in [
                provider.next_snapshot(),
                provider.next_snapshot(),
                provider.next_snapshot(),
                provider.next_snapshot(),
                provider.next_snapshot(),
                provider.next_snapshot(),
            ]
        ]

        self.assertEqual(
            observed,
            [
                ("Focused", "Deep Work", 15),
                ("Assisted Deep Work", "Development Loop", 30),
                ("Passive Drift", "General Browsing", 45),
                ("Compulsive Drift", "Passive Consumption", 75),
                ("Overloaded", "Unknown Context", 90),
                ("Focused", "Deep Work", 15),
            ]
        )

    def test_controller_overlap_guard_prevents_second_worker(self):
        guard = AnalysisInFlightGuard()

        self.assertTrue(guard.try_acquire())
        self.assertFalse(guard.try_acquire())

        guard.release()

        self.assertTrue(guard.try_acquire())


if __name__ == "__main__":
    unittest.main()
