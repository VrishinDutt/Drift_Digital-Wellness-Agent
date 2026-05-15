import Foundation

struct ContextClassifier {
    /// Maps app/window identity into a coarse attention context.
    ///
    /// Python reference:
    /// - `ml.context_classifier`
    /// - `telemetry.browser_context`
    ///
    /// Future native implementation can combine NSWorkspace foreground app
    /// identity with user-granted Accessibility window titles. It must stay
    /// metadata-only: no screenshots, OCR, page body scraping, clipboard access,
    /// keystroke capture, or hidden private content collection.
    func classify(appName: String, windowTitle: String?) -> AttentionContext {
        let app = appName.lowercased()
        let title = windowTitle?.lowercased() ?? ""
        let combined = "\(app) \(title)"

        if containsAny(combined, ["youtube", "shorts", "reels", "tiktok", "instagram", "netflix"]) {
            return .passiveConsumption
        }

        if containsAny(combined, ["reddit", "feed", "popular"]) {
            return .passiveConsumption
        }

        if containsAny(combined, ["spotify", "apple music", "music", "endel", "lofi"]) {
            return .audioRegulation
        }

        if containsAny(combined, ["stackoverflow", "stack overflow", "stackexchange", "stack exchange", "github"]) {
            return .research
        }

        if containsAny(combined, ["chatgpt", "codex", "claude", "perplexity"]) {
            return .assistedWork
        }

        if containsAny(combined, ["xcode", "terminal", "iterm", "visual studio code", "vscode", "python", "swift"]) {
            return .development
        }

        if containsAny(combined, ["docs", "notion", "obsidian", "pages", "word"]) {
            return .deepWork
        }

        if containsAny(app, ["safari", "chrome", "arc", "firefox", "edge"]) {
            return .generalBrowsing
        }

        return .unknown
    }

    private func containsAny(_ value: String, _ tokens: [String]) -> Bool {
        tokens.contains { value.contains($0) }
    }
}
