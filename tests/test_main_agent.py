import contextlib
import io
import unittest
from unittest.mock import patch

import agent.main_agent as main_agent


class MainAgentTests(unittest.TestCase):

    def behavior(self, intervention_type="none"):
        return {
            "context": "Deep Work",
            "spotify_context": None,
            "ccs": 15,
            "reasoning": {
                "state": "Focused",
                "summary": "Low drift pressure."
            },
            "intervention": {
                "type": intervention_type,
                "message": "Try a slow breath."
            }
        }

    def test_no_ui_returns_snapshot_without_launching_overlay(self):
        behavior = self.behavior(intervention_type="grounding")

        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.object(
                main_agent,
                "load_memory",
                return_value={"recent_states": [], "last_intervention_at": 0}
            ))
            stack.enter_context(patch.object(
                main_agent,
                "load_logs",
                return_value=[]
            ))
            stack.enter_context(patch.object(
                main_agent,
                "process_behavior",
                return_value=behavior
            ))
            stack.enter_context(patch.object(
                main_agent,
                "load_timeline",
                return_value=[]
            ))
            present_intervention = stack.enter_context(patch.object(
                main_agent,
                "present_intervention"
            ))

            snapshot = main_agent.run_agent(
                show_ui=False,
                verbose=False,
                persist_state=False,
                update_learning=False
            )

        present_intervention.assert_not_called()
        self.assertEqual(snapshot["status"], "ok")
        self.assertEqual(snapshot["context"], "Deep Work")
        self.assertEqual(snapshot["ccs"], 15)
        self.assertFalse(snapshot["ui_interventions_enabled"])
        self.assertEqual(snapshot["privacy_mode"], "local-only")

    def test_verbose_false_suppresses_stdout(self):
        behavior = self.behavior()
        stdout = io.StringIO()

        with contextlib.ExitStack() as stack:
            stack.enter_context(patch.object(
                main_agent,
                "load_memory",
                return_value={"recent_states": [], "last_intervention_at": 0}
            ))
            stack.enter_context(patch.object(
                main_agent,
                "load_logs",
                return_value=[]
            ))
            stack.enter_context(patch.object(
                main_agent,
                "process_behavior",
                return_value=behavior
            ))
            stack.enter_context(patch.object(
                main_agent,
                "load_timeline",
                return_value=[]
            ))

            with contextlib.redirect_stdout(stdout):
                main_agent.run_agent(
                    show_ui=False,
                    verbose=False,
                    persist_state=False,
                    update_learning=False
                )

        self.assertEqual(stdout.getvalue(), "")


if __name__ == "__main__":
    unittest.main()
