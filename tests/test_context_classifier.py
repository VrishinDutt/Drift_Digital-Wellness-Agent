import unittest

from ml.context_classifier import classify_context


class ContextClassifierTests(unittest.TestCase):

    def test_browser_passive_consumption(self):
        self.assertEqual(
            classify_context("Safari", "YouTube - Shorts"),
            "Passive Consumption"
        )

    def test_browser_focused_work(self):
        self.assertEqual(
            classify_context("Chrome", "Stack Overflow - Python ImportError"),
            "Development Loop"
        )

    def test_ai_app(self):
        self.assertEqual(
            classify_context("Codex", ""),
            "Assisted Deep Work"
        )

    def test_deep_work_app(self):
        self.assertEqual(
            classify_context("Xcode", "Project"),
            "Development Loop"
        )

    def test_chatgpt_browser_context_is_assisted_deep_work(self):
        self.assertEqual(
            classify_context("Safari", "ChatGPT - Refactor notes"),
            "Assisted Deep Work"
        )


if __name__ == "__main__":
    unittest.main()
