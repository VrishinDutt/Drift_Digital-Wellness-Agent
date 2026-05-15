import SwiftUI

enum DesignTokens {
    enum ColorToken {
        static let appBackground = Color(red: 0.03, green: 0.04, blue: 0.05)
        static let glassBackground = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.16)
        static let primaryText = Color(red: 0.94, green: 0.97, blue: 0.98)
        static let secondaryText = Color(red: 0.66, green: 0.71, blue: 0.75)
        static let quietText = Color(red: 0.50, green: 0.55, blue: 0.60)

        static func state(_ state: AttentionState) -> Color {
            switch state {
            case .focused:
                return Color(red: 0.20, green: 0.75, blue: 1.00)
            case .assistedDeepWork:
                return Color(red: 0.45, green: 0.62, blue: 1.00)
            case .developmentLoop:
                return Color(red: 0.28, green: 0.56, blue: 1.00)
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
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 22
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 24
        static let innerCard: CGFloat = 18
        static let pill: CGFloat = 12
    }

    enum Typography {
        static let appTitle = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let state = Font.system(size: 26, weight: .semibold, design: .rounded)
        static let metric = Font.system(size: 13, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 11, weight: .medium, design: .rounded)
        static let intervention = Font.system(size: 14, weight: .regular, design: .rounded)
    }
}
