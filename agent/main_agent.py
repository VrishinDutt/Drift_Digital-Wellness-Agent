import os
import sys
import time
from datetime import datetime

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from agent.intervention_learning import (
    print_learning,
    update_effectiveness
)
from agent.memory import (
    load_memory,
    update_memory
)
from agent.session_timeline import (
    add_state,
    load_timeline,
    print_timeline
)
from core.behavior_engine import process_behavior
from core.paths import data_path
from ml.context_classifier import classify_context
from telemetry.log_store import load_activity_logs, parse_timestamp

LOG_FILE = data_path("activity_log.json")
LOG_WINDOW_SIZE = 20
INTERVENTION_COOLDOWN_SECONDS = 120
TELEMETRY_STALE_SECONDS = 10


def load_logs():
    return load_activity_logs(LOG_FILE, limit=LOG_WINDOW_SIZE)


def print_observation(behavior):
    dominant_context = behavior["context"]
    spotify_context = behavior["spotify_context"]
    reasoning = behavior["reasoning"]
    intervention = behavior["intervention"]

    print("\n=== LIVE AGENT OBSERVATION ===\n")
    print(f"Dominant Context: {dominant_context}")
    print(f"CCS: {behavior['ccs']}")

    if spotify_context:
        print(
            "Spotify Context: "
            f"{spotify_context['track']} by "
            f"{', '.join(spotify_context['artists'])}"
        )

    print("\n=== REASONING ===\n")
    print(reasoning)

    print("\n=== INTERVENTION ===\n")
    print(intervention)


def cooldown_elapsed(memory, current_time):
    last_intervention_at = memory.get("last_intervention_at", 0)

    return (
        current_time - last_intervention_at
        > INTERVENTION_COOLDOWN_SECONDS
    )


def present_intervention(intervention):
    if intervention["type"] == "grounding":
        from ui.breathing_overlay import BreathingOverlay

        BreathingOverlay()
        return

    from ui.intentionality_overlay import show_overlay

    show_overlay(
        intervention["message"]
    )


def get_timeline_preview(limit=5):
    timeline = load_timeline()
    if not isinstance(timeline, list):
        return []
    return timeline[-limit:]


def seconds_since_timestamp(timestamp):
    parsed = parse_timestamp(timestamp)

    if parsed is None:
        return None

    now = (
        datetime.now(parsed.tzinfo)
        if parsed.tzinfo
        else datetime.now()
    )

    return max(0, (now - parsed).total_seconds())


def get_latest_context(log):
    if not log:
        return "Unknown Context"

    return log.get("active_context") or classify_context(
        log.get("active_app", "Unknown"),
        log.get("window_title", "Unknown")
    )


def build_telemetry_metadata(logs):
    snapshot_timestamp = datetime.now().isoformat(timespec="seconds")
    latest_log = logs[-1] if logs else {}
    latest_timestamp = latest_log.get("timestamp")
    latest_age = seconds_since_timestamp(latest_timestamp)

    if latest_age is None:
        freshness = "unknown"
    elif latest_age <= TELEMETRY_STALE_SECONDS:
        freshness = "live"
    else:
        freshness = "stale"

    return {
        "snapshot_timestamp": snapshot_timestamp,
        "latest_telemetry_timestamp": latest_timestamp,
        "latest_telemetry_age_seconds": latest_age,
        "telemetry_freshness": freshness,
        "telemetry_platform": latest_log.get("platform", "Unknown"),
        "telemetry_adapter": latest_log.get(
            "telemetry_adapter",
            latest_log.get("collector", "Unknown")
        ),
        "telemetry_permission_status": latest_log.get(
            "permission_status",
            "unknown"
        ),
        "latest_active_app": latest_log.get("active_app", "Unknown"),
        "latest_window_title": latest_log.get("window_title", "Unknown"),
        "latest_active_context": get_latest_context(latest_log),
        "latest_is_idle": latest_log.get("is_idle", False),
        "rows_used_for_analysis": len(logs),
    }


def apply_idle_display_guard(snapshot):
    if not snapshot.get("latest_is_idle"):
        return snapshot

    snapshot["ccs"] = min(snapshot.get("ccs", 0), 20)
    snapshot["context"] = "Idle / Paused"
    snapshot["reasoning"] = {
        "state": "Idle / Paused",
        "intervention_needed": False,
        "reason": "System appears idle; no active drift inferred."
    }
    snapshot["intervention"] = {
        "type": "none",
        "message": "Quiet while the system is idle."
    }
    snapshot["idle_display_guard_applied"] = True

    return snapshot


def apply_stale_display_guard(snapshot):
    if (
        snapshot.get("telemetry_freshness") == "stale"
        and snapshot.get("ccs", 0) >= 70
    ):
        snapshot["ccs"] = 55
        snapshot["reasoning"] = {
            "state": "Neutral",
            "intervention_needed": False,
            "reason": "Telemetry is stale; waiting for a fresh signal."
        }
        snapshot["intervention"] = {
            "type": "none",
            "message": "Waiting for fresh telemetry before interpreting state."
        }
        snapshot["stale_display_guard_applied"] = True

    return snapshot


def build_behavior_snapshot(
    behavior,
    ui_interventions_enabled=True,
    status="ok",
    logs=None
):
    logs = logs or []
    snapshot = {
        "status": status,
        "context": behavior.get("context", "Unknown Context"),
        "ccs": behavior.get("ccs", 0),
        "reasoning": behavior.get("reasoning", {}),
        "intervention": behavior.get("intervention", {}),
        "spotify_context": behavior.get("spotify_context"),
        "timeline_preview": get_timeline_preview(),
        "ui_interventions_enabled": bool(ui_interventions_enabled),
        "privacy_mode": "local-only",
    }

    snapshot.update(build_telemetry_metadata(logs))

    return apply_idle_display_guard(
        apply_stale_display_guard(snapshot)
    )


def run_agent(
    show_ui=True,
    verbose=True,
    *,
    persist_state=True,
    update_learning=True
):
    memory = load_memory()
    previous_states = memory["recent_states"]
    logs = load_logs()
    behavior = process_behavior(
        logs,
        previous_states
    )

    if verbose:
        print_observation(behavior)

    current_time = time.time()
    intervention = behavior["intervention"]
    ccs = behavior["ccs"]
    state = behavior["reasoning"]["state"]
    dominant_context = behavior["context"]
    last_intervention_at = None

    should_intervene = (
        intervention["type"] != "none"
        and cooldown_elapsed(memory, current_time)
    )

    if should_intervene:
        last_intervention_at = current_time

        if show_ui:
            present_intervention(intervention)
        elif verbose:
            print("\nIntervention UI suppressed.\n")

        success = ccs < 50

        if update_learning:
            update_effectiveness(
                intervention["type"],
                success
            )

            if verbose:
                print_learning()

    elif intervention["type"] != "none" and verbose:
        print(
            "\nIntervention suppressed "
            "due to cooldown.\n"
        )

    if persist_state:
        add_state(
            state,
            dominant_context,
            ccs
        )

        if verbose:
            print_timeline()

        update_memory(
            state,
            intervention["type"],
            last_intervention_at=last_intervention_at
        )

    return build_behavior_snapshot(
        behavior,
        ui_interventions_enabled=show_ui,
        logs=logs
    )


if __name__ == "__main__":
    run_agent()
