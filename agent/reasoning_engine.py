def infer_attention_state(
    ccs,
    context,
    previous_states
):
    productive_contexts = {
        "Assisted Deep Work",
        "Development Loop",
        "Deep Work",
        "Focused Work",
        "Writing"
    }

    if context in productive_contexts and ccs < 35:
        return {
            "state": "Focused",
            "intervention_needed": False,
            "reason": "Productive attention loop detected."
        }

    if context == "Passive Consumption":

        if ccs >= 50:
            return {
                "state": "Compulsive Drift",
                "intervention_needed": True,
                "reason": "High passive consumption with elevated switching behavior."
            }

        return {
            "state": "Passive Drift",
            "intervention_needed": True,
            "reason": "Passive consumption detected."
        }

    if ccs >= 70:

        return {
            "state": "Overloaded",
            "intervention_needed": True,
            "reason": "Behavior suggests attentional fragmentation."
        }

    if previous_states.count("Compulsive Drift") >= 2:

        return {
            "state": "Recurring Drift",
            "intervention_needed": True,
            "reason": "Repeated compulsive patterns detected."
        }

    return {
        "state": "Neutral",
        "intervention_needed": False,
        "reason": "No concerning behavioral signals."
    }


if __name__ == "__main__":

    test = infer_attention_state(
        ccs=65,
        context="Passive Consumption",
        previous_states=["Focused", "Compulsive Drift"]
    )

    print(test)
