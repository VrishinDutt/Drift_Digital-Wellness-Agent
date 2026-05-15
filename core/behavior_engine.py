import os
import sys
from collections import Counter

PROJECT_ROOT = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from agent.reasoning_engine import infer_attention_state
from context.spotify_provider import get_spotify_context
from interventions.adaptive_interventions import choose_intervention
from ml.context_classifier import classify_context
from ml.drift_analyzer import calculate_drift_score


def bound_score(score):
    return max(0, min(score, 100))


def infer_dominant_context(contexts):
    if not contexts:
        return "Unknown Context"

    counter = Counter(contexts)

    return counter.most_common(1)[0][0]


def get_log_context(log):
    return log.get("active_context") or classify_context(
        log.get("active_app", "Unknown"),
        log.get("window_title", "Unknown")
    )


def apply_spotify_adjustment(ccs, spotify_context):
    if not spotify_context:
        return ccs

    signal = spotify_context.get("signal", {})
    tags = signal.get("tags", [])

    if "high_stimulation" in tags:
        ccs += 10

    if "calming" in tags:
        ccs -= 5

    return ccs


def process_behavior(logs, previous_states):
    contexts = [
        get_log_context(log)
        for log in logs
    ]

    dominant_context = infer_dominant_context(contexts)
    spotify_context = get_spotify_context()
    raw_ccs = calculate_drift_score(logs)
    ccs = bound_score(
        apply_spotify_adjustment(raw_ccs, spotify_context)
    )
    reasoning = infer_attention_state(
        ccs,
        dominant_context,
        previous_states
    )
    intervention = choose_intervention(
        reasoning["state"],
        dominant_context,
        previous_states
    )

    return {
        "context": dominant_context,
        "contexts": contexts,
        "spotify_context": spotify_context,
        "ccs": ccs,
        "raw_ccs": raw_ccs,
        "reasoning": reasoning,
        "intervention": intervention
    }
