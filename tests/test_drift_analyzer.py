import unittest

from ml.drift_analyzer import calculate_drift_score


class DriftAnalyzerTests(unittest.TestCase):

    def test_empty_or_single_log_has_no_drift(self):
        self.assertEqual(calculate_drift_score([]), 0)
        self.assertEqual(
            calculate_drift_score([
                {"active_app": "Terminal", "window_title": "zsh"}
            ]),
            0
        )

    def test_app_title_and_context_changes_raise_score(self):
        logs = [
            {
                "active_app": "Safari",
                "window_title": "GitHub Pull Request",
                "active_context": "Development Loop"
            },
            {
                "active_app": "Safari",
                "window_title": "YouTube",
                "active_context": "Passive Consumption"
            },
            {
                "active_app": "Terminal",
                "window_title": "zsh",
                "active_context": "Deep Work"
            }
        ]

        self.assertGreater(calculate_drift_score(logs), 0)

    def test_non_passive_switching_is_bounded_below_max(self):
        logs = [
            {
                "active_app": "Safari" if index % 2 else "Terminal",
                "window_title": f"title-{index}"
            }
            for index in range(80)
        ]

        score = calculate_drift_score(logs)

        self.assertGreater(score, 0)
        self.assertLess(score, 100)

    def test_productive_switching_loop_stays_low(self):
        logs = [
            {
                "active_app": "ChatGPT",
                "window_title": "Refactor plan"
            },
            {
                "active_app": "Terminal",
                "window_title": "pytest tests"
            },
            {
                "active_app": "Codex",
                "window_title": "digital_wellness_agent"
            },
            {
                "active_app": "VSCode",
                "window_title": "ml/drift_analyzer.py"
            },
            {
                "active_app": "Chrome",
                "window_title": "Stack Overflow - Python ImportError"
            },
            {
                "active_app": "Terminal",
                "window_title": "python -m unittest"
            },
            {
                "active_app": "ChatGPT",
                "window_title": "Context calibration"
            }
        ]

        self.assertLessEqual(calculate_drift_score(logs), 35)

    def test_passive_consumption_loop_scores_high(self):
        logs = [
            {
                "active_app": "Safari",
                "window_title": "YouTube Shorts"
            },
            {
                "active_app": "Reddit",
                "window_title": "Home feed"
            },
            {
                "active_app": "Instagram",
                "window_title": "Reels"
            },
            {
                "active_app": "Safari",
                "window_title": "YouTube"
            },
            {
                "active_app": "Reddit",
                "window_title": "Popular"
            },
            {
                "active_app": "Instagram",
                "window_title": "Explore"
            }
        ]

        self.assertGreaterEqual(calculate_drift_score(logs), 70)

    def test_mixed_productive_and_passive_loop_is_elevated(self):
        logs = [
            {
                "active_app": "Terminal",
                "window_title": "python -m unittest"
            },
            {
                "active_app": "ChatGPT",
                "window_title": "Debugging help"
            },
            {
                "active_app": "Safari",
                "window_title": "YouTube Shorts"
            },
            {
                "active_app": "VSCode",
                "window_title": "core/behavior_engine.py"
            },
            {
                "active_app": "Reddit",
                "window_title": "Home feed"
            }
        ]

        score = calculate_drift_score(logs)

        self.assertGreater(score, 35)
        self.assertLess(score, 100)

    def test_unknown_switching_is_elevated_without_locking_at_max(self):
        logs = [
            {
                "active_app": f"UnknownApp{index % 3}",
                "window_title": f"Untitled {index}"
            }
            for index in range(12)
        ]

        score = calculate_drift_score(logs)

        self.assertGreater(score, 0)
        self.assertLess(score, 100)


if __name__ == "__main__":
    unittest.main()
