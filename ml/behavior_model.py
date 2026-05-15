import os
import sys

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from core.paths import data_path
from ml.context_classifier import classify_context
from ml.drift_analyzer import calculate_drift_score
from telemetry.log_store import load_activity_logs

LOG_FILE = data_path("activity_log.json")


def load_logs():
    return load_activity_logs(LOG_FILE)


def classify_state(ccs):
    if ccs < 20:
        return "Focused"

    if ccs < 50:
        return "Drifting"

    if ccs < 80:
        return "Compulsive"

    return "Overloaded"


def summarize_contexts(logs):
    contexts = [
        log.get("active_context")
        or classify_context(
            log.get("active_app", "Unknown"),
            log.get("window_title", "Unknown")
        )
        for log in logs
    ]

    return contexts


if __name__ == "__main__":
    logs = load_logs()
    ccs = calculate_drift_score(logs)
    state = classify_state(ccs)

    print("\n=== BEHAVIORAL ANALYSIS ===\n")
    print(f"Compulsive Consumption Score: {ccs}")
    print(f"Behavioral State: {state}")
