import SwiftUI

struct BreathingOrbView: View {
    let phase: BreathingPhase
    let accent: Color
    let onDismiss: () -> Void

    private var orbScale: CGFloat {
        switch phase {
        case .inhale, .hold:
            return 1.06
        case .exhale, .rest:
            return 0.78
        }
    }

    private var orbOpacity: Double {
        switch phase {
        case .inhale:
            return 0.96
        case .hold:
            return 1.0
        case .exhale:
            return 0.78
        case .rest:
            return 0.66
        }
    }

    private var glowOpacity: Double {
        switch phase {
        case .inhale, .hold:
            return 0.28
        case .exhale:
            return 0.16
        case .rest:
            return 0.10
        }
    }

    private var glowBlur: CGFloat {
        switch phase {
        case .inhale, .hold:
            return 14
        case .exhale:
            return 9
        case .rest:
            return 7
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
            orb
                .accessibilityLabel("Breathing reset")
                .accessibilityValue(phase.displayText)

            Text(phase.displayText)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Spacer(minLength: DesignTokens.Spacing.xs)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .frame(width: 24, height: 24)
                    .background(DesignTokens.ColorToken.panelBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .strokeBorder(DesignTokens.ColorToken.quietBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss breathing reset")
            .help("Dismiss")
        }
        .frame(minHeight: 90)
        .animation(.easeInOut(duration: phase.duration), value: phase)
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(glowOpacity))
                .frame(width: 74, height: 74)
                .scaleEffect(1.22)
                .blur(radius: glowBlur)

            Circle()
                .fill(accent.opacity(0.10))
                .background(.thinMaterial, in: Circle())
                .frame(width: 72, height: 72)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.32),
                            accent.opacity(0.34),
                            accent.opacity(0.12)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 54
                    )
                )
                .frame(width: 72, height: 72)

            Circle()
                .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.8)
                .frame(width: 72, height: 72)
        }
        .frame(width: 92, height: 92)
        .scaleEffect(orbScale)
        .opacity(orbOpacity)
        .shadow(color: accent.opacity(glowOpacity), radius: 16, x: 0, y: 0)
        .drawingGroup()
    }
}

#if DEBUG
struct BreathingOrbView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingOrbView(
            phase: .inhale,
            accent: DesignTokens.ColorToken.state(.overloaded),
            onDismiss: {}
        )
        .padding()
        .background(DesignTokens.ColorToken.appBackground)
    }
}
#endif
