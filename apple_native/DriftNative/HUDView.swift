import SwiftUI

struct HUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    @State private var ringPulse = false

    private var snapshot: AttentionSnapshot {
        viewModel.snapshot
    }

    private var accent: Color {
        DesignTokens.ColorToken.state(snapshot.state)
    }

    private var secondaryAccent: Color {
        DesignTokens.ColorToken.stateSecondary(snapshot.state)
    }

    var body: some View {
        ZStack {
            background

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                header

                HStack(alignment: .center, spacing: DesignTokens.Spacing.lg) {
                    stateRing

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(snapshot.state.displayName)
                            .font(DesignTokens.Typography.state)
                            .foregroundStyle(accent)
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .animation(.easeInOut(duration: 0.35), value: snapshot.state)

                        Text(snapshot.context.displayName)
                            .font(DesignTokens.Typography.metric)
                            .foregroundStyle(DesignTokens.ColorToken.secondaryText)

                        HStack(spacing: DesignTokens.Spacing.sm) {
                            scorePill
                            telemetryPill
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                    .overlay(DesignTokens.ColorToken.quietBorder)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    vitalRow(label: "Latest app", value: snapshot.latestApp)

                    if let latestTitle = snapshot.latestTitle, !latestTitle.isEmpty {
                        vitalRow(label: "Surface", value: latestTitle)
                    }
                }

                interventionPanel

                footer
            }
            .padding(DesignTokens.Spacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .overlay(glassOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .stroke(DesignTokens.ColorToken.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.34), radius: 28, x: 0, y: 18)
            .padding(DesignTokens.Spacing.lg)
        }
        .onChange(of: snapshot.id) { _, _ in
            triggerRingPulse()
        }
    }

    private var background: some View {
        ZStack {
            DesignTokens.ColorToken.appBackground

            LinearGradient(
                colors: [
                    secondaryAccent.opacity(0.22),
                    Color.clear,
                    accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
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

            statusDot
        }
    }

    private var stateRing: some View {
        let progress = CGFloat(snapshot.driftScore) / 100

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accent.opacity(0.18),
                            accent.opacity(0.045),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: DesignTokens.Layout.ringSize / 2
                    )
                )

            Circle()
                .stroke(DesignTokens.ColorToken.ringTrack, lineWidth: DesignTokens.Layout.ringLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accent, secondaryAccent, accent],
                        center: .center
                    ),
                    style: StrokeStyle(
                        lineWidth: DesignTokens.Layout.ringLineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.45), value: snapshot.driftScore)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("\(snapshot.driftScore)")
                    .font(DesignTokens.Typography.score)
                    .foregroundStyle(accent)
                    .contentTransition(.numericText())

                Text("DRIFT")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
            }
        }
        .frame(width: DesignTokens.Layout.ringSize, height: DesignTokens.Layout.ringSize)
        .scaleEffect(ringPulse ? 1.025 : 1)
        .animation(.easeOut(duration: 0.28), value: ringPulse)
        .accessibilityLabel("Drift score \(snapshot.driftScore)")
    }

    private var scorePill: some View {
        Text("Drift \(snapshot.driftScore)")
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent.opacity(0.11))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(accent.opacity(0.26), lineWidth: 1)
            )
    }

    private var telemetryPill: some View {
        let statusColor = DesignTokens.ColorToken.telemetry(snapshot.telemetryStatus)

        return Text(snapshot.telemetryStatus.displayName)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.10))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.28), lineWidth: 1)
            )
    }

    private var statusDot: some View {
        let statusColor = DesignTokens.ColorToken.telemetry(snapshot.telemetryStatus)

        return HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)

            Text("Telemetry \(snapshot.telemetryStatus.displayName)")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignTokens.ColorToken.panelBackground)
        .clipShape(Capsule())
    }

    private func vitalRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }

    private var interventionPanel: some View {
        Text(snapshot.interventionMessage)
            .font(DesignTokens.Typography.intervention)
            .foregroundStyle(DesignTokens.ColorToken.primaryText)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.ColorToken.elevatedPanelBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous)
                    .stroke(accent.opacity(0.24), lineWidth: 1)
            )
    }

    private var footer: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Text("Updated \(snapshot.lastUpdated, style: .time)")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)

            Spacer()

            Toggle(
                "Auto",
                isOn: Binding(
                    get: { viewModel.isAutoCycleEnabled },
                    set: { isEnabled in
                        if isEnabled {
                            viewModel.startMockCycle()
                        } else {
                            viewModel.stopMockCycle()
                        }
                    }
                )
            )
            .toggleStyle(.switch)
            .controlSize(.mini)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.ColorToken.secondaryText)

            Button {
                viewModel.advanceSnapshot()
            } label: {
                Label("Next State", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(accent)
        }
    }

    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.04),
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
    }

    private func triggerRingPulse() {
        withAnimation(.easeOut(duration: 0.16)) {
            ringPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeOut(duration: 0.32)) {
                ringPulse = false
            }
        }
    }
}

#if DEBUG
struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView(viewModel: HUDViewModel())
    }
}
#endif
