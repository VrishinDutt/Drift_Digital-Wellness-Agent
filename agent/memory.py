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
from telemetry.log_store import load_json, save_json

MEMORY_FILE = data_path("agent_memory.json")

DEFAULT_MEMORY = {
    "recent_states": [],
    "recent_interventions": [],
    "last_intervention_at": 0
}

def load_memory():
    memory = load_json(MEMORY_FILE, DEFAULT_MEMORY)
    memory.setdefault("recent_states", [])
    memory.setdefault("recent_interventions", [])
    memory.setdefault("last_intervention_at", 0)

    return memory

def save_memory(memory):
    save_json(MEMORY_FILE, memory)

def update_memory(state, intervention, last_intervention_at=None):

    memory = load_memory()

    memory["recent_states"].append(state)
    memory["recent_interventions"].append(intervention)

    memory["recent_states"] = memory["recent_states"][-5:]
    memory["recent_interventions"] = memory["recent_interventions"][-5:]

    if last_intervention_at is not None:
        memory["last_intervention_at"] = last_intervention_at

    save_memory(memory)

def print_memory():

    memory = load_memory()

    print("\n=== AGENT MEMORY ===\n")

    print("Recent States:")
    print(memory["recent_states"])

    print("\nRecent Interventions:")
    print(memory["recent_interventions"])
