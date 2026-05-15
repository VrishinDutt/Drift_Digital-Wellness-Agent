import random

INTERVENTIONS = {

    "Focused": [
        "You seem intentionally engaged.",
        "Steady cognitive rhythm detected."
    ],

    "Drifting": [
        "Still intentional?",
        "You’ve switched contexts frequently.",
        "Pause for a breath before continuing."
    ],

    "Compulsive": [
        "You seem caught in a reactive loop.",
        "Want a 60-second reset?",
        "Try grounding attention before reopening apps."
    ],

    "Overloaded": [
        "Your interaction pattern suggests cognitive fatigue.",
        "Consider stepping away briefly.",
        "Try a breathing reset."
    ]
}

def generate_intervention(state):

    options = INTERVENTIONS.get(state, [])

    if not options:
        return "No intervention available."

    return random.choice(options)

if __name__ == "__main__":

    test_states = [
        "Focused",
        "Drifting",
        "Compulsive",
        "Overloaded"
    ]

    for state in test_states:

        intervention = generate_intervention(state)

        print(f"\n[{state}]")
        print(intervention)