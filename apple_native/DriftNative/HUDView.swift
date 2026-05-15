import SwiftUI

struct HUDView: View {
    let snapshot: AttentionSnapshot
    let advanceAction: () -> Void

    private var accent: Color {
        DesignTokens.ColorToken.state(snapshot.state)
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                header

                HStack(alignment: .center, spacing: DesignTokens.Spacing.lg) {
                    stateRing

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(snapshot.state.displayName)
                            .font(DesignTokens.Typography.state)
                            .foregroundStyle(accent)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)

                        Text(snapshot.context.displayName)
                            .font(DesignTokens.Typography.metric)
                            .foregroundStyle(DesignTokens.ColorToken.secondaryText)

                        Text("Drift \(snapshot.driftScore)")
                            .font(DesignTokens.Typography.metric)
                            .foregroundStyle(DesignTokens.ColorToken.primaryText)

                        Text("Latest: \(snapshot.latestApp)")
                            .font(DesignTokens.Typography.metric)
                            .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        statusPill
                    }
                }

                interventionCard

                HStack {
                    Text("Updated \(snapshot.lastUpdated, style: .time)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.quietText)

                    Spacer()

                    Button("Demo Next", action: advanceAction)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(glassBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .stroke(DesignTokens.ColorToken.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: 12)
            .padding(DesignTokens.Spacing.lg)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Drift")
                    .font(DesignTokens.Typography.appTitle)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)

                Text("attention vitals")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            }

            Spacer()
        }
    }

    private var stateRing: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 132, height: 132)

            Circle()
                .stroke(accent.opacity(0.24), lineWidth: 16)
                .frame(width: 112, height: 112)

            Circle()
                .trim(from: 0, to: CGFloat(snapshot.driftScore) / 100)
                .stroke(accent, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 112, height: 112)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("\(snapshot.driftScore)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent)

                Text("DRIFT")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
            }
        }
        .accessibilityLabel("Drift score \(snapshot.driftScore)")
    }

    private var statusPill: some View {
        Text("Telemetry: \(snapshot.telemetryStatus.displayName)")
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.10))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.30), lineWidth: 1)
            )
    }

    private var interventionCard: some View {
        Text(snapshot.interventionMessage)
            .font(DesignTokens.Typography.intervention)
            .foregroundStyle(DesignTokens.ColorToken.primaryText)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.md)
            .background(Color.white.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous)
                    .stroke(accent.opacity(0.30), lineWidth: 1)
            )
    }

    private var glassBackground: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.055)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusColor: Color {
        switch snapshot.telemetryStatus {
        case .mocked:
            return Color(red: 0.45, green: 0.62, blue: 1.00)
        case .live:
            return Color(red: 0.35, green: 0.82, blue: 0.65)
        case .stale:
            return Color(red: 0.95, green: 0.70, blue: 0.28)
        case .unavailable:
            return DesignTokens.ColorToken.secondaryText
        }
    }
}

#if DEBUG
struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView(
            snapshot: MockTelemetryProvider.demoSnapshots[0],
            advanceAction: {}
        )
    }
}
#endif
