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

from ml.context_classifier import classify_context

PRODUCTIVE_CONTEXTS = {
    "Assisted Deep Work",
    "Development Loop",
    "Deep Work",
    "Focused Work",
    "Writing"
}

PASSIVE_CONTEXTS = {
    "Passive Consumption"
}

REGULATION_CONTEXTS = {
    "Background Regulation"
}

UNKNOWN_CONTEXTS = {
    "Unknown Context"
}


def get_context(log):
    return log.get(
        "active_context",
        classify_context(
            log.get("active_app", "Unknown"),
            log.get("window_title", "Unknown")
        )
    )


def is_productive_context(context):
    return context in PRODUCTIVE_CONTEXTS


def is_passive_context(context):
    return context in PASSIVE_CONTEXTS


def is_unknown_context(context):
    return context in UNKNOWN_CONTEXTS


def bounded(score, cap=100):
    return max(0, min(int(round(score)), cap))


def calculate_drift_score(logs):

    if len(logs) < 2:
        return 0

    app_switches = 0

    title_switches = 0

    context_switches = 0

    repeated_reopens = 0

    previous_app = None
    previous_title = None
    previous_context = None

    app_sequence = []
    context_sequence = []

    for log in logs:

        app = log.get("active_app", "Unknown")
        title = log.get("window_title", "Unknown")
        context = get_context(log)

        app_sequence.append(app)
        context_sequence.append(context)

        if previous_app and app != previous_app:
            app_switches += 1

        if (
            previous_title
            and title != previous_title
        ):
            title_switches += 1

        if (
            previous_context
            and context != previous_context
        ):
            context_switches += 1

        previous_app = app
        previous_title = title
        previous_context = context

    counts = Counter(app_sequence)

    for app, count in counts.items():
        if count >= 4:
            repeated_reopens += 1

    total = len(context_sequence)
    productive_count = sum(
        1
        for context in context_sequence
        if is_productive_context(context)
    )
    passive_count = sum(
        1
        for context in context_sequence
        if is_passive_context(context)
    )
    unknown_count = sum(
        1
        for context in context_sequence
        if is_unknown_context(context)
    )
    regulation_count = sum(
        1
        for context in context_sequence
        if context in REGULATION_CONTEXTS
    )

    productive_ratio = productive_count / total
    passive_ratio = passive_count / total
    unknown_ratio = unknown_count / total
    regulation_ratio = regulation_count / total

    all_productive = productive_ratio + regulation_ratio == 1

    if all_productive:
        score = (
            app_switches * 1.25 +
            title_switches * 0.5 +
            context_switches * 1.0 +
            repeated_reopens * 2
        )
        return bounded(score, cap=35)

    if passive_ratio >= 0.6:
        score = (
            app_switches * 9 +
            title_switches * 4 +
            context_switches * 5 +
            repeated_reopens * 12 +
            passive_count * 8
        )
        return bounded(score, cap=100)

    if unknown_ratio >= 0.6:
        score = (
            app_switches * 3.5 +
            title_switches * 1.5 +
            context_switches * 3 +
            repeated_reopens * 5 +
            unknown_count * 2
        )
        return bounded(score, cap=80)

    score = (
        app_switches * 3 +
        title_switches * 1.5 +
        context_switches * 4 +
        repeated_reopens * 7 +
        passive_count * 7 +
        unknown_count * 2 -
        productive_count * 1.5
    )

    return bounded(score, cap=90)

if __name__ == "__main__":

    test_logs = [
        {"active_app": "Safari"},
        {"active_app": "ChatGPT"},
        {"active_app": "Safari"},
        {"active_app": "Safari"},
        {"active_app": "Reddit"},
        {"active_app": "Safari"},
    ]

    print(
        calculate_drift_score(test_logs)
    )
