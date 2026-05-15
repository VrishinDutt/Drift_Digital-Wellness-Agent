import Foundation

struct DriftAnalyzer {
    /// Native counterpart to Python's `ml.drift_analyzer`.
    ///
    /// The important calibration principle is that switching is not inherently
    /// bad. Xcode -> Terminal -> ChatGPT -> GitHub can be a healthy development
    /// loop, while YouTube -> Reddit -> short-form feeds can indicate passive or
    /// compulsive drift. Context quality and repetition matter more than raw
    /// transition count.
    func score(samples: [TelemetrySample], context: AttentionContext) -> Int {
        guard let latest = samples.last else {
            return 0
        }

        if latest.isIdle {
            return 5
        }

        let recent = Array(samples.suffix(8))
        let appSwitches = zip(recent, recent.dropFirst()).filter { previous, current in
            previous.appName.caseInsensitiveCompare(current.appName) != .orderedSame
        }.count
        let passiveRepeats = recent.filter { sample in
            let app = sample.appName.lowercased()
            let title = sample.windowTitle?.lowercased() ?? ""
            return app.contains("youtube")
                || app.contains("reddit")
                || app.contains("instagram")
                || title.contains("shorts")
                || title.contains("reels")
                || title.contains("feed")
        }.count

        var baseScore: Int
        switch context {
        case .deepWork, .development, .assistedWork, .research:
            baseScore = 15
        case .audioRegulation:
            baseScore = 10
        case .generalBrowsing:
            baseScore = 35
        case .passiveConsumption:
            baseScore = 55
        case .unknown:
            baseScore = 45
        }

        baseScore += appSwitches * transitionWeight(for: context)
        baseScore += passiveRepeats * 6

        if isProductive(context) {
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
        case .audioRegulation:
            return 1
        case .generalBrowsing:
            return 5
        case .passiveConsumption:
            return 8
        case .unknown:
            return 6
        }
    }

    private func isProductive(_ context: AttentionContext) -> Bool {
        switch context {
        case .deepWork, .development, .assistedWork, .research:
            return true
        case .audioRegulation, .generalBrowsing, .passiveConsumption, .unknown:
            return false
        }
    }
}
