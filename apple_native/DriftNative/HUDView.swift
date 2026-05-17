import SwiftUI

struct HUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    @State private var isExpanded = false
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

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                header
                glance
                compactVitals
                gentleSignal
                controls

                if isExpanded {
                    expandedDetail
                        .transition(.opacity)
                        .clipped()
                        .compositingGroup()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .overlay(glassOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .strokeBorder(DesignTokens.ColorToken.glassBorder, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card - 1, style: .continuous)
                    .strokeBorder(DesignTokens.ColorToken.innerHighlight, lineWidth: 0.5)
                    .padding(1)
            )
            .shadow(color: accent.opacity(0.08), radius: 22, x: 0, y: 10)
            .shadow(color: .black.opacity(0.30), radius: 26, x: 0, y: 16)
            .padding(DesignTokens.Spacing.sm)
            .frame(maxWidth: DesignTokens.Layout.hudMaxWidth)
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
                    secondaryAccent.opacity(0.16),
                    Color.clear,
                    accent.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Drift")
                    .font(DesignTokens.Typography.appTitle)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)

                Text("digital rhythm")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            }

            Spacer(minLength: DesignTokens.Spacing.sm)
            modePill
        }
    }

    private var glance: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
            stateRing

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(snapshot.state.displayName)
                    .font(DesignTokens.Typography.state)
                    .foregroundStyle(accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(snapshot.context.displayName)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .lineLimit(1)

                Text("Drift \(snapshot.driftScore)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var stateRing: some View {
        let progress = CGFloat(snapshot.driftScore) / 100

        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            accent.opacity(0.16),
                            accent.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: DesignTokens.Layout.ringSize / 2
                    )
                )

            Circle()
                .stroke(DesignTokens.ColorToken.ringTrack, lineWidth: DesignTokens.Layout.ringLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [accent, secondaryAccent, accent], center: .center),
                    style: StrokeStyle(lineWidth: DesignTokens.Layout.ringLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: snapshot.driftScore)

            VStack(spacing: 1) {
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
        .contentShape(Circle())
        .scaleEffect(ringPulse ? 1.025 : 1)
        .animation(.easeOut(duration: 0.24), value: ringPulse)
        .hudCircularHoverGlow(accent: accent)
        .accessibilityLabel("Drift score \(snapshot.driftScore)")
    }

    private var compactVitals: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            tinyCard(label: "Latest app", value: snapshot.latestApp)
            tinyCard(label: "Mode", value: viewModel.telemetryMode.displayName)
        }
    }

    private func tinyCard(label: String, value: String) -> some View {
        InteractiveHUDCard(accent: accent, scale: 1.02, padding: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)

                Text(value)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.78)
            }
        }
    }

    private var gentleSignal: some View {
        InteractiveHUDCard(accent: accent, scale: 1.018, padding: DesignTokens.Spacing.sm) {
            Text(viewModel.compactInterventionLine)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var controls: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Picker(
                "Mode",
                selection: Binding(
                    get: { viewModel.telemetryMode },
                    set: { viewModel.setTelemetryMode($0) }
                )
            ) {
                ForEach(TelemetryMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 152)
            .hudHoverLift(accent: accent, scale: 1.015)

            Spacer(minLength: DesignTokens.Spacing.xs)

            if viewModel.telemetryMode == .mock {
                Button {
                    viewModel.advanceSnapshot()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(accent)
                .help("Next State")
                .hudHoverLift(accent: accent, scale: 1.03)
            }

            Button {
                toggleExpanded()
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(accent)
            .help(isExpanded ? "Collapse" : "Expand")
            .hudHoverLift(accent: accent, scale: 1.03)
        }
    }

    private var expandedDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Divider()
                    .overlay(DesignTokens.ColorToken.quietBorder)

                detailCard("Current") {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        detailRow("State", snapshot.state.displayName)
                        detailRow("Context", snapshot.context.displayName)
                        detailRow("Latest", snapshot.latestApp)
                        detailRow("Status", snapshot.telemetryStatus.displayName)
                    }
                }

                detailCard("Why") {
                    Text(viewModel.readingExplanation)
                        .font(DesignTokens.Typography.intervention)
                        .foregroundStyle(DesignTokens.ColorToken.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.hasSoundscapeSuggestion {
                    detailCard("Rhythm") {
                        rhythmDetail
                    }
                }

                detailCard("Apple Music") {
                    appleMusicDetail
                }

                detailCard("Intervention") {
                    interventionDetail
                }

                detailCard("Recent Signal") {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(viewModel.recentSignal.prefix(5), id: \.timestamp) { sample in
                            recentSampleRow(sample)
                        }
                    }
                }

                detailCard("Privacy") {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("No screenshots, keystrokes, clipboard, or page text are collected.")
                            .font(DesignTokens.Typography.intervention)
                            .foregroundStyle(DesignTokens.ColorToken.primaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Buffer \(viewModel.bufferSizeDescription) • Updated \(snapshot.lastUpdated, style: .time)")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.ColorToken.quietText)
                    }
                }

                detailCard("System") {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        detailRow("Mode", viewModel.telemetryMode.displayName)
                        detailRow("Buffer", viewModel.bufferSizeDescription)
                        detailRow("Status", snapshot.telemetryStatus.displayName)
                    }
                }

                detailCard("Diagnostics") {
                    diagnosticsList
                }
            }
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxHeight: DesignTokens.Layout.expandedDetailMaxHeight)
        .clipped()
    }

    private var diagnosticsList: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            if viewModel.diagnosticEntries.isEmpty {
                Text("No recent internal events.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            } else {
                ForEach(viewModel.diagnosticEntries.prefix(5)) { entry in
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                        Text(entry.category.displayName)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(accent)
                            .frame(width: 70, alignment: .leading)

                        Text(entry.message)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var interventionDetail: some View {
        let intervention = snapshot.intervention

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(intervention.title)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)

                Text(intervention.message)
                    .font(DesignTokens.Typography.intervention)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.interventionStatus)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            }

            if let selectedIntention = viewModel.selectedIntention {
                Text("Intention set: \(selectedIntention)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(accent.opacity(0.10))
                    .clipShape(Capsule())
            }

            if intervention.hasChoices {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(intervention.choices, id: \.self) { choice in
                        capsuleButton(choice) {
                            viewModel.selectInterventionChoice(choice)
                        }
                    }
                }
            }

            if intervention.kind == .breathingReset {
                breathingResetControl
            }
        }
    }

    private var rhythmDetail: some View {
        let plan = snapshot.rhythmPlan

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                rhythmChip(plan.displayName)
                rhythmChip(plan.intensity.displayName)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Suggested rhythm")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)

                Text(viewModel.suggestedSoundscapeMode.displayName)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            VStack(alignment: .leading, spacing: 3) {
                detailRow("Feel", plan.texture.displayName)
                detailRow("Pace", plan.cadence)
                detailRow("Asset", viewModel.suggestedSoundscapeAssetName)
            }

            Text(viewModel.rhythmStatus)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let availabilityMessage = viewModel.suggestedSoundscapeAvailabilityMessage {
                Text(availabilityMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    capsuleButton("Play local cue", isDisabled: !viewModel.isSuggestedSoundscapeAvailable) {
                        viewModel.playSuggestedSoundscape()
                    }

                    capsuleButton("Stop", isDisabled: !viewModel.soundscapePlaybackState.isActive) {
                        viewModel.stopSoundscape()
                    }
                }

                capsuleButton("Test breathing cue") {
                    viewModel.playBreathingCue()
                }
            }

            Text(viewModel.soundscapePlaybackStatus)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .fixedSize(horizontal: false, vertical: true)

            Text(plan.boundary)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appleMusicDetail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Apple Music: \(viewModel.appleMusicStatusLabel)")
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(viewModel.appleMusicDetailMessage)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                appleMusicStatusLine("Connection", viewModel.appleMusicConnectionCapabilityLabel)
                appleMusicStatusLine("Playback", viewModel.appleMusicPlaybackStatusLabel)
                appleMusicStatusLine("Local cues", viewModel.appleMusicLocalCuesStatusLabel)
                appleMusicStatusLine("Subscription", viewModel.appleMusicSubscriptionStatusLabel)

                if let permissionStatus = viewModel.appleMusicPermissionStatusLabel {
                    appleMusicStatusLine("Permission", permissionStatus)
                }
            }

            HStack(spacing: DesignTokens.Spacing.xs) {
                if viewModel.canRequestAppleMusicAuthorization {
                    capsuleButton("Enable Apple Music") {
                        Task {
                            await viewModel.requestAppleMusicAuthorization()
                        }
                    }
                }

                if viewModel.isAppleMusicConnected {
                    capsuleButton("Check Status") {
                        Task {
                            await viewModel.checkAppleMusicStatus()
                        }
                    }

                    capsuleButton("Open Music") {
                        Task {
                            await viewModel.openMusicApp()
                        }
                    }
                } else if !viewModel.canRequestAppleMusicAuthorization {
                    capsuleButton("Check Status") {
                        Task {
                            await viewModel.checkAppleMusicStatus()
                        }
                    }
                }
            }

            if let lastErrorMessage = viewModel.appleMusicLastErrorMessage {
                Text(lastErrorMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func appleMusicStatusLine(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .frame(width: 84, alignment: .leading)

            Text(value)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }

    private func rhythmChip(_ value: String) -> some View {
        Text(value)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(accent)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(accent.opacity(0.10))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
    }

    private var breathingResetControl: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if viewModel.isBreathingResetActive {
                HStack(spacing: DesignTokens.Spacing.md) {
                    breathingCue

                    Button {
                        viewModel.dismissBreathingReset()
                    } label: {
                        Text("Dismiss")
                    }
                    .buttonStyle(.plain)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(DesignTokens.ColorToken.panelBackground)
                    .clipShape(Capsule())
                    .hudHoverLift(accent: accent, scale: 1.02)
                }
            } else {
                capsuleButton("Begin breathing cue") {
                    viewModel.startBreathingReset()
                }
            }
        }
    }

    private var breathingCue: some View {
        let progress: CGFloat = viewModel.breathingPhase == .inhale ? 0.82 : 0.42

        return ZStack {
            Circle()
                .stroke(DesignTokens.ColorToken.ringTrack, lineWidth: 6)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 2.2), value: viewModel.breathingPhase)

            Text(viewModel.breathingPhase.rawValue)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
        }
        .frame(width: 72, height: 72)
        .scaleEffect(viewModel.breathingPhase == .inhale ? 1.03 : 0.98)
        .animation(.easeInOut(duration: 2.2), value: viewModel.breathingPhase)
    }

    private func capsuleButton(
        _ title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(accent.opacity(0.10))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(accent.opacity(0.22), lineWidth: 1)
                )
                .opacity(isDisabled ? 0.46 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .hudHoverLift(accent: accent, scale: 1.035)
    }

    private func detailCard<Content: View>(
        _ title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)

            InteractiveHUDCard(accent: accent, scale: 1.012, padding: DesignTokens.Spacing.sm) {
                content()
            }
        }
    }

    private func recentSampleRow(_ sample: TelemetrySample) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
            Text(sample.appName)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: DesignTokens.Spacing.sm)

            Text(sample.timestamp, style: .time)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .frame(width: 48, alignment: .leading)

            Text(value)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }

    private var modePill: some View {
        let statusColor = DesignTokens.ColorToken.telemetry(snapshot.telemetryStatus)

        return HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(snapshot.telemetryStatus.displayName)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(statusColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.09))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(0.24), lineWidth: 1)
        )
    }

    private var glassOverlay: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DesignTokens.ColorToken.liquidGlassTop,
                        Color.white.opacity(0.045),
                        DesignTokens.ColorToken.liquidGlassBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .allowsHitTesting(false)
    }

    private func toggleExpanded() {
        var transaction = Transaction(animation: .easeInOut(duration: 0.16))
        transaction.disablesAnimations = false

        withTransaction(transaction) {
            isExpanded.toggle()
        }
    }

    private func triggerRingPulse() {
        withAnimation(.easeOut(duration: 0.14)) {
            ringPulse = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.easeOut(duration: 0.24)) {
                ringPulse = false
            }
        }
    }
}

private struct InteractiveHUDCard<Content: View>: View {
    let accent: Color
    let padding: CGFloat
    let content: () -> Content
    @State private var isHovered = false

    init(
        accent: Color,
        scale: CGFloat = 1.02,
        padding: CGFloat = DesignTokens.Spacing.sm,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accent = accent
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.105 : 0.075),
                                DesignTokens.ColorToken.elevatedPanelBackground,
                                Color.black.opacity(0.035)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous)
                    .strokeBorder(isHovered ? accent.opacity(0.28) : DesignTokens.ColorToken.quietBorder, lineWidth: 1)
            )
            .shadow(
                color: isHovered ? accent.opacity(0.12) : .black.opacity(0.10),
                radius: isHovered ? 9 : 5,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private struct HoverLiftModifier: ViewModifier {
    let accent: Color
    let scale: CGFloat
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.pill, style: .continuous)
                    .strokeBorder(isHovered ? accent.opacity(0.20) : .clear, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .shadow(
                color: isHovered ? accent.opacity(0.12) : .clear,
                radius: isHovered ? 7 : 0,
                x: 0,
                y: isHovered ? 3 : 0
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private struct CircularHoverGlowModifier: ViewModifier {
    let accent: Color
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .strokeBorder(isHovered ? accent.opacity(0.28) : .clear, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .shadow(
                color: isHovered ? accent.opacity(0.18) : .clear,
                radius: isHovered ? 10 : 0,
                x: 0,
                y: 0
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

private extension View {
    func hudHoverLift(accent: Color, scale: CGFloat = 1.02) -> some View {
        modifier(HoverLiftModifier(accent: accent, scale: scale))
    }

    func hudCircularHoverGlow(accent: Color) -> some View {
        modifier(CircularHoverGlowModifier(accent: accent))
    }
}

#if DEBUG
struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView(viewModel: HUDViewModel())
    }
}
#endif
