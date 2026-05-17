import SwiftUI

enum DesignTokens {
    enum ColorToken {
        static let appBackground = Color(red: 0.075, green: 0.082, blue: 0.092)
        static let glassBackground = Color.white.opacity(0.10)
        static let panelBackground = Color.white.opacity(0.065)
        static let elevatedPanelBackground = Color.white.opacity(0.095)
        static let liquidGlassTop = Color.white.opacity(0.19)
        static let liquidGlassBottom = Color.black.opacity(0.08)
        static let innerHighlight = Color.white.opacity(0.22)
        static let glassBorder = Color.white.opacity(0.18)
        static let quietBorder = Color.white.opacity(0.08)
        static let ringTrack = Color.white.opacity(0.12)
        static let primaryText = Color(red: 0.94, green: 0.97, blue: 0.98)
        static let secondaryText = Color(red: 0.66, green: 0.71, blue: 0.75)
        static let quietText = Color(red: 0.50, green: 0.55, blue: 0.60)
        static let previewMode = Color(red: 0.54, green: 0.48, blue: 1.00)
        static let nowMode = Color(red: 0.35, green: 0.82, blue: 0.65)

        static func state(_ state: AttentionState) -> Color {
            switch state {
            case .focused:
                return Color(red: 0.20, green: 0.75, blue: 1.00)
            case .assistedDeepWork:
                return Color(red: 0.45, green: 0.62, blue: 1.00)
            case .developmentLoop:
                return Color(red: 0.28, green: 0.56, blue: 1.00)
            case .researchFlow:
                return Color(red: 0.36, green: 0.84, blue: 0.92)
            case .neutral:
                return Color(red: 0.58, green: 0.63, blue: 0.67)
            case .passiveDrift:
                return Color(red: 0.95, green: 0.70, blue: 0.28)
            case .compulsiveDrift:
                return Color(red: 1.00, green: 0.48, blue: 0.20)
            case .overloaded:
                return Color(red: 1.00, green: 0.36, blue: 0.52)
            case .idlePaused:
                return Color(red: 0.45, green: 0.56, blue: 0.64)
            case .unknown:
                return Color(red: 0.54, green: 0.57, blue: 0.60)
            }
        }

        static func stateSecondary(_ state: AttentionState) -> Color {
            switch state {
            case .focused:
                return Color(red: 0.24, green: 0.46, blue: 1.00)
            case .assistedDeepWork:
                return Color(red: 0.22, green: 0.82, blue: 0.95)
            case .developmentLoop:
                return Color(red: 0.18, green: 0.36, blue: 0.86)
            case .researchFlow:
                return Color(red: 0.24, green: 0.56, blue: 1.00)
            case .neutral:
                return Color(red: 0.44, green: 0.48, blue: 0.52)
            case .passiveDrift:
                return Color(red: 0.74, green: 0.50, blue: 0.20)
            case .compulsiveDrift:
                return Color(red: 0.86, green: 0.28, blue: 0.12)
            case .overloaded:
                return Color(red: 0.95, green: 0.42, blue: 0.72)
            case .idlePaused:
                return Color(red: 0.32, green: 0.42, blue: 0.50)
            case .unknown:
                return Color(red: 0.40, green: 0.43, blue: 0.46)
            }
        }

        static func telemetry(_ status: TelemetryStatus) -> Color {
            switch status {
            case .mocked:
                return Color(red: 0.45, green: 0.62, blue: 1.00)
            case .live:
                return Color(red: 0.35, green: 0.82, blue: 0.65)
            case .stale:
                return Color(red: 0.95, green: 0.70, blue: 0.28)
            case .unavailable:
                return secondaryText
            }
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 18
        static let xl: CGFloat = 26
    }

    enum Radius {
        static let card: CGFloat = 20
        static let innerCard: CGFloat = 13
        static let pill: CGFloat = 12
    }

    enum Layout {
        static let hudMinWidth: CGFloat = 360
        static let hudIdealWidth: CGFloat = 392
        static let hudMaxWidth: CGFloat = 430
        static let hudMinHeight: CGFloat = 228
        static let hudIdealHeight: CGFloat = 268
        static let hudMaxHeight: CGFloat = 640
        static let expandedDetailMaxHeight: CGFloat = 336
        static let ringSize: CGFloat = 94
        static let ringLineWidth: CGFloat = 9
    }

    enum Typography {
        static let appTitle = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let state = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let score = Font.system(size: 25, weight: .semibold, design: .rounded)
        static let metric = Font.system(size: 13, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
        static let intervention = Font.system(size: 13, weight: .regular, design: .rounded)
    }
}
