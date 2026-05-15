import json
import tempfile
import unittest
from pathlib import Path

from telemetry.log_store import (
    load_activity_logs,
    load_jsonl,
    normalize_activity_record
)


class LogStoreTests(unittest.TestCase):

    def write_lines(self, lines):
        directory = tempfile.TemporaryDirectory()
        path = Path(directory.name) / "activity_log.json"

        with open(path, "w") as f:
            for line in lines:
                f.write(line + "\n")

        self.addCleanup(directory.cleanup)

        return path

    def test_load_jsonl_skips_corrupted_lines(self):
        path = self.write_lines([
            json.dumps({"active_app": "Terminal"}),
            "{not-json"
        ])

        self.assertEqual(
            load_jsonl(path),
            [{"active_app": "Terminal"}]
        )

    def test_mixed_schema_prefers_current_rows(self):
        path = self.write_lines([
            json.dumps({
                "timestamp": "2026-05-14T10:00:00",
                "active_app": "Terminal",
                "window_title": "zsh"
            }),
            json.dumps({
                "schema_version": 2,
                "timestamp": "2026-05-14T10:00:01",
                "active_app": "Safari",
                "window_title": "GitHub",
                "active_context": "Focused Work"
            }),
            "{bad-json"
        ])

        logs = load_activity_logs(path)

        self.assertEqual(len(logs), 1)
        self.assertEqual(logs[0]["schema_version"], 2)
        self.assertEqual(logs[0]["active_app"], "Safari")

    def test_legacy_only_rows_are_normalized(self):
        path = self.write_lines([
            json.dumps({
                "timestamp": "2026-05-14 10:00:00",
                "active_app": "Terminal"
            })
        ])

        logs = load_activity_logs(path)

        self.assertEqual(len(logs), 1)
        self.assertTrue(logs[0]["_normalized_from_legacy"])
        self.assertEqual(logs[0]["window_title"], "Unknown")

    def test_malformed_activity_record_is_skipped(self):
        self.assertIsNone(
            normalize_activity_record({"window_title": "missing app"})
        )


if __name__ == "__main__":
    unittest.main()
