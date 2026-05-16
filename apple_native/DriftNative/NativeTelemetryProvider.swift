import AppKit
import Foundation

struct NativeTelemetryProvider {
    static let unavailableAppName = "Unavailable"

    /// v0.1 telemetry is intentionally app-name only. Future native layers can
    /// add AppKit activation notifications, user-granted window metadata, a menu
    /// bar app, a floating HUD window, and local timeline storage without adding
    /// screenshots, keystrokes, clipboard reads, or page text scraping.
    func currentSample() -> TelemetrySample {
        let application = NSWorkspace.shared.frontmostApplication
        let bundleIdentifier = application?.bundleIdentifier
        let appName = application?.localizedName?.trimmedNonEmpty
            ?? bundleIdentifier?.trimmedNonEmpty
            ?? Self.unavailableAppName

        return TelemetrySample(
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            windowTitle: nil,
            isIdle: false,
            timestamp: Date()
        )
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
