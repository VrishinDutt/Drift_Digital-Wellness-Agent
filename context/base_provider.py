class ContextSignal:

    def __init__(
        self,
        source,
        context_type,
        intensity,
        duration,
        tags
    ):

        self.source = source
        self.context_type = context_type
        self.intensity = max(0, min(intensity, 100))
        self.duration = duration
        self.tags = tags

    def to_dict(self):

        return {
            "source": self.source,
            "context_type": self.context_type,
            "intensity": self.intensity,
            "duration": self.duration,
            "tags": self.tags
        }
