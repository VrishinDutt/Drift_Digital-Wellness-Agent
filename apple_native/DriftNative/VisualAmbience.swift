import AppKit
import Foundation
import SwiftUI

struct VisualAmbienceTint: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    var color: Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }
}

struct VisualAmbiencePreset: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let cognitiveIntent: String
    let recommendedFor: [AttentionState]
    let tint: VisualAmbienceTint
    let wallpaperAssetName: String?

    static let library = VisualAmbiencePreset(
        id: "library",
        title: "Library",
        subtitle: "Quiet task focus",
        cognitiveIntent: "Create a steady, low-novelty setting for sustained attention.",
        recommendedFor: [.focused, .assistedDeepWork, .developmentLoop, .researchFlow],
        tint: VisualAmbienceTint(red: 0.48, green: 0.68, blue: 0.92, opacity: 1),
        wallpaperAssetName: "ambience_library"
    )

    static let coffeeShop = VisualAmbiencePreset(
        id: "coffee-shop",
        title: "Coffee Shop",
        subtitle: "Light social hum",
        cognitiveIntent: "Add gentle forward motion without forcing a hard reset.",
        recommendedFor: [.neutral, .passiveDrift],
        tint: VisualAmbienceTint(red: 0.86, green: 0.58, blue: 0.34, opacity: 1),
        wallpaperAssetName: "ambience_coffee_shop"
    )

    static let researchLab = VisualAmbiencePreset(
        id: "research-lab",
        title: "Research Lab",
        subtitle: "Structured deep work",
        cognitiveIntent: "Support tool loops that still serve one clear task.",
        recommendedFor: [.focused, .assistedDeepWork, .developmentLoop, .researchFlow],
        tint: VisualAmbienceTint(red: 0.36, green: 0.84, blue: 0.76, opacity: 1),
        wallpaperAssetName: "ambience_research_lab"
    )

    static let windowSeat = VisualAmbiencePreset(
        id: "window-seat",
        title: "Window Seat",
        subtitle: "Soft re-entry",
        cognitiveIntent: "Make a transition feel available without pushing urgency.",
        recommendedFor: [.neutral, .passiveDrift, .idlePaused],
        tint: VisualAmbienceTint(red: 0.64, green: 0.78, blue: 0.94, opacity: 1),
        wallpaperAssetName: "ambience_window_seat"
    )

    static let nightDesk = VisualAmbiencePreset(
        id: "night-desk",
        title: "Night Desk",
        subtitle: "Dim, contained focus",
        cognitiveIntent: "Lower visual intensity while preserving a work surface.",
        recommendedFor: [.focused, .assistedDeepWork, .neutral],
        tint: VisualAmbienceTint(red: 0.52, green: 0.47, blue: 0.84, opacity: 1),
        wallpaperAssetName: "ambience_night_desk"
    )

    static let quietStudio = VisualAmbiencePreset(
        id: "quiet-studio",
        title: "Quiet Studio",
        subtitle: "Neutral reset space",
        cognitiveIntent: "Offer a calm default when the signal is weak or sticky.",
        recommendedFor: [.neutral, .compulsiveDrift, .unknown],
        tint: VisualAmbienceTint(red: 0.70, green: 0.74, blue: 0.72, opacity: 1),
        wallpaperAssetName: "ambience_quiet_studio"
    )

    static let rainRoom = VisualAmbiencePreset(
        id: "rain-room",
        title: "Rain Room",
        subtitle: "Low-stimulus downshift",
        cognitiveIntent: "Reduce novelty and make stopping feel less abrupt.",
        recommendedFor: [.compulsiveDrift, .overloaded],
        tint: VisualAmbienceTint(red: 0.34, green: 0.56, blue: 0.70, opacity: 1),
        wallpaperAssetName: "ambience_rain_room"
    )

    static let openAir = VisualAmbiencePreset(
        id: "open-air",
        title: "Open Air",
        subtitle: "Breathing room",
        cognitiveIntent: "Widen the setting when attention feels crowded or paused.",
        recommendedFor: [.overloaded, .idlePaused, .unknown],
        tint: VisualAmbienceTint(red: 0.50, green: 0.78, blue: 0.58, opacity: 1),
        wallpaperAssetName: "ambience_open_air"
    )

    static let all: [VisualAmbiencePreset] = [
        .library,
        .coffeeShop,
        .researchLab,
        .windowSeat,
        .nightDesk,
        .quietStudio,
        .rainRoom,
        .openAir
    ]

    static func preset(withID id: String) -> VisualAmbiencePreset {
        all.first { $0.id == id } ?? .quietStudio
    }
}

struct VisualAmbienceRecommendation: Equatable {
    let preset: VisualAmbiencePreset
    let rationale: String
}

struct VisualAmbienceEngine {
    func recommendation(for snapshot: AttentionSnapshot) -> VisualAmbienceRecommendation {
        recommendation(
            for: snapshot.state,
            context: snapshot.context,
            driftScore: snapshot.driftScore
        )
    }

    func recommendedPreset(for snapshot: AttentionSnapshot) -> VisualAmbiencePreset {
        recommendation(for: snapshot).preset
    }

    func visiblePresets(for snapshot: AttentionSnapshot) -> [VisualAmbiencePreset] {
        let recommendation = recommendation(for: snapshot).preset
        let fallbackIDs = candidateIDs(
            for: snapshot.state,
            context: snapshot.context,
            recommendedID: recommendation.id
        )

        return uniquePresets(from: [recommendation.id] + fallbackIDs)
    }

    private func recommendation(
        for state: AttentionState,
        context: AttentionContext,
        driftScore: Int
    ) -> VisualAmbienceRecommendation {
        switch state {
        case .focused, .assistedDeepWork, .researchFlow:
            if context == .research || context == .development {
                return make("research-lab", "Structured work maps to Research Lab.")
            }

            return make("library", "Steady focus maps to Library.")
        case .developmentLoop:
            return make("research-lab", "Development Loop maps to Research Lab.")
        case .passiveDrift:
            if context == .generalBrowsing {
                return make("coffee-shop", "Passive browsing maps to Coffee Shop.")
            }

            return make("window-seat", "Passive Drift maps to Window Seat.")
        case .compulsiveDrift:
            if driftScore >= 70 || context == .passiveConsumption {
                return make("rain-room", "Sticky loops map to Rain Room.")
            }

            return make("quiet-studio", "Compulsive Drift maps to Quiet Studio.")
        case .overloaded:
            if driftScore >= 75 {
                return make("rain-room", "High overload maps to Rain Room.")
            }

            return make("open-air", "Overload maps to Open Air.")
        case .idlePaused:
            if context == .paused || driftScore <= 20 {
                return make("open-air", "Paused rhythm maps to Open Air.")
            }

            return make("window-seat", "Idle rhythm maps to Window Seat.")
        case .neutral:
            if context == .generalBrowsing {
                return make("coffee-shop", "Neutral browsing maps to Coffee Shop.")
            }

            return make("quiet-studio", "Mixed signal maps to Quiet Studio.")
        case .unknown:
            return make("quiet-studio", "Unknown signal maps to Quiet Studio.")
        }
    }

    private func candidateIDs(
        for state: AttentionState,
        context: AttentionContext,
        recommendedID: String
    ) -> [String] {
        switch state {
        case .focused, .assistedDeepWork, .developmentLoop, .researchFlow:
            return [recommendedID, "library", "research-lab", "night-desk", "quiet-studio"]
        case .passiveDrift:
            return [recommendedID, "window-seat", "coffee-shop", "open-air", "quiet-studio"]
        case .compulsiveDrift:
            return [recommendedID, "rain-room", "quiet-studio", "window-seat", "open-air"]
        case .overloaded:
            return [recommendedID, "rain-room", "open-air", "quiet-studio", "window-seat"]
        case .idlePaused:
            return [recommendedID, "open-air", "window-seat", "coffee-shop", "quiet-studio"]
        case .neutral:
            if context == .generalBrowsing {
                return [recommendedID, "coffee-shop", "window-seat", "library", "night-desk"]
            }

            return [recommendedID, "quiet-studio", "library", "night-desk", "coffee-shop"]
        case .unknown:
            return [recommendedID, "quiet-studio", "window-seat", "open-air", "library"]
        }
    }

    private func uniquePresets(from ids: [String]) -> [VisualAmbiencePreset] {
        var seen: [String] = []
        var presets: [VisualAmbiencePreset] = []

        for id in ids where !seen.contains(id) {
            seen.append(id)
            presets.append(VisualAmbiencePreset.preset(withID: id))

            if presets.count == 4 {
                break
            }
        }

        return presets
    }

    private func make(_ presetID: String, _ rationale: String) -> VisualAmbienceRecommendation {
        VisualAmbienceRecommendation(
            preset: VisualAmbiencePreset.preset(withID: presetID),
            rationale: rationale
        )
    }
}

enum VisualAmbienceApplyResult: Equatable {
    case applied(String)
    case previewOnly(String)
    case failed(String)

    var message: String {
        switch self {
        case .applied(let message), .previewOnly(let message), .failed(let message):
            return message
        }
    }
}

@MainActor
final class VisualAmbienceManager {
    static let previewOnlyMessage = "Preview only — wallpaper asset unavailable."

    private static let assetSubdirectory = "VisualAmbienceAssets"
    private static let supportedImageExtensions = ["heic", "jpg", "jpeg", "png"]

    func isWallpaperAssetAvailable(for preset: VisualAmbiencePreset) -> Bool {
        wallpaperAssetURL(for: preset) != nil
    }

    func assetUnavailableMessage(for preset: VisualAmbiencePreset) -> String? {
        isWallpaperAssetAvailable(for: preset) ? nil : Self.previewOnlyMessage
    }

    func applyPreset(_ preset: VisualAmbiencePreset) -> VisualAmbienceApplyResult {
        guard let assetURL = wallpaperAssetURL(for: preset) else {
            return .previewOnly(Self.previewOnlyMessage)
        }

        guard let display = NSScreen.main ?? NSScreen.screens.first else {
            return .failed("No active display is available for ambience changes.")
        }

        do {
            try NSWorkspace.shared.setDesktopImageURL(assetURL, for: display, options: [:])
            return .applied("Applied \(preset.title).")
        } catch {
            return .failed("Could not apply ambience: \(error.localizedDescription)")
        }
    }

    private func wallpaperAssetURL(for preset: VisualAmbiencePreset) -> URL? {
        guard let assetName = preset.wallpaperAssetName else {
            return nil
        }

        let name = assetName as NSString
        let assetExtension = name.pathExtension

        if !assetExtension.isEmpty {
            return url(forResource: name.deletingPathExtension, withExtension: assetExtension)
        }

        for imageExtension in Self.supportedImageExtensions {
            if let url = url(forResource: assetName, withExtension: imageExtension) {
                return url
            }
        }

        return nil
    }

    private func url(forResource resource: String, withExtension fileExtension: String) -> URL? {
        Bundle.main.url(
            forResource: resource,
            withExtension: fileExtension,
            subdirectory: Self.assetSubdirectory
        ) ?? Bundle.main.url(forResource: resource, withExtension: fileExtension)
    }
}
