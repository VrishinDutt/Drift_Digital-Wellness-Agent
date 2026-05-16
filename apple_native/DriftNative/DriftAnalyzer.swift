import Foundation

struct DriftAnalyzer {
    /// Native counterpart to Python's `ml.drift_analyzer`.
    ///
    /// The important calibration principle is that switching is not inherently
    /// bad. Xcode -> Terminal -> ChatGPT -> GitHub can be a healthy development
    /// loop, while YouTube -> Reddit -> short-form feeds can indicate passive or
    /// compulsive drift. Context quality and repetition matter more than raw
    /// transition count.
    ///
    /// HUDViewModel owns the bounded sample buffer. This analyzer only works on
    /// that recent slice, then narrows again to a small suffix for interpretable
    /// features. Keep the score simple, deterministic, and legible. Avoid
    /// overfitting app names, and never label intentional work loops as pathology
    /// just because they involve switching between tools.
    func score(samples: [TelemetrySample], context: AttentionContext) -> Int {
        guard let latest = samples.last else {
            return 0
        }

        if latest.isIdle {
            return 5
        }

        let features = DriftFeatureSnapshot(samples: Array(samples.suffix(8)))

        var baseScore: Int
        switch context {
        case .deepWork, .development, .assistedWork, .research:
            baseScore = 15
        case .audioRegulation, .paused:
            baseScore = 10
        case .generalBrowsing:
            baseScore = 35
        case .passiveConsumption:
            baseScore = 55
        case .unknown:
            baseScore = 45
        }

        baseScore += features.transitionCount * transitionWeight(for: context)
        baseScore += features.passiveHintCount * 6

        if features.isWorkLoop {
            baseScore = min(baseScore, 35)
        }

        if features.repeatedAppCount >= 5 && context == .unknown {
            baseScore += 6
        }

        if isWorkAligned(context) {
            return min(baseScore, 45)
        }

        if context == .unknown {
            return min(baseScore, 75)
        }

        return min(max(baseScore, 0), 100)
    }

    private func transitionWeight(for context: AttentionContext) -> Int {
        switch context {
        case .deepWork, .development, .assistedWork, .research:
            return 2
        case .audioRegulation, .paused:
            return 1
        case .generalBrowsing:
            return 5
        case .passiveConsumption:
            return 8
        case .unknown:
            return 6
        }
    }

    private func isWorkAligned(_ context: AttentionContext) -> Bool {
        switch context {
        case .deepWork, .development, .assistedWork, .research:
            return true
        case .audioRegulation, .paused, .generalBrowsing, .passiveConsumption, .unknown:
            return false
        }
    }
}

private struct DriftFeatureSnapshot {
    let samples: [TelemetrySample]

    var latestApp: String {
        samples.last?.appName ?? "Unknown"
    }

    var transitionCount: Int {
        zip(samples, samples.dropFirst()).filter { previous, current in
            previous.appName.caseInsensitiveCompare(current.appName) != .orderedSame
        }.count
    }

    var repeatedAppCount: Int {
        guard let latest = samples.last else {
            return 0
        }

        return samples.filter { sample in
            sample.appName.caseInsensitiveCompare(latest.appName) == .orderedSame
        }.count
    }

    var passiveHintCount: Int {
        samples.filter { sample in
            let app = sample.appName.lowercased()
            let title = sample.windowTitle?.lowercased() ?? ""
            return app.contains("youtube")
                || app.contains("reddit")
                || app.contains("instagram")
                || title.contains("shorts")
                || title.contains("reels")
                || title.contains("feed")
        }.count
    }

    var isWorkLoop: Bool {
        let workApps = ["xcode", "terminal", "iterm", "chatgpt", "codex", "github", "visual studio code", "vscode"]
        let appNames = Set(samples.map { $0.appName.lowercased() })
        let workMatches = appNames.filter { app in
            workApps.contains { app.contains($0) }
        }

        return transitionCount > 0 && !workMatches.isEmpty && workMatches.count == appNames.count
    }
}
