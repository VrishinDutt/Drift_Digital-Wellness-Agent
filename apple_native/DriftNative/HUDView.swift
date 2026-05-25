import Foundation
import SwiftUI

struct HUDView: View {
    @ObservedObject var viewModel: HUDViewModel
    @State private var isExpanded = false
    @State private var ringPulse = false
    @State private var isShowingLearnMore = false
    @State private var isShowingModeChooser = false

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

                if isExpanded {
                    expandedDetail
                        .transition(.opacity)
                        .clipped()
                        .compositingGroup()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
            .background(liquidPanelFill)
            .overlay(glassHighlight)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                    .strokeBorder(DesignTokens.ColorToken.glassBorder, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card - 1, style: .continuous)
                    .strokeBorder(DesignTokens.ColorToken.innerHighlight, lineWidth: 0.5)
                    .padding(1)
            )
            .shadow(color: accent.opacity(0.12), radius: 24, x: 0, y: 10)
            .shadow(color: .black.opacity(0.24), radius: 30, x: 0, y: 16)
            .padding(DesignTokens.Spacing.sm)
            .frame(maxWidth: DesignTokens.Layout.hudMaxWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onChange(of: snapshot.id) { _, _ in
            triggerRingPulse()

            if isExpanded {
                viewModel.openSuggestedBreathingOrbIfNeeded()
            }
        }
    }

    private var background: some View {
        ZStack {
            DesignTokens.ColorToken.appBackground

            LinearGradient(
                colors: [
                    DesignTokens.ColorToken.appBackground,
                    secondaryAccent.opacity(0.13),
                    DesignTokens.ColorToken.appBackground,
                    accent.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
            Text("Drift")
                .font(DesignTokens.Typography.appTitle)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)

            Spacer(minLength: DesignTokens.Spacing.sm)
            modePill
        }
    }

    private var glance: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
            stateRing

            VStack(alignment: .leading, spacing: 4) {
                Text(compactStateLabel)
                    .font(DesignTokens.Typography.state)
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .allowsTightening(true)

                Text(compactContextLabel)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.90)
                    .allowsTightening(true)

                HStack(spacing: 5) {
                    Image(systemName: compactCueIcon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.88))
                        .frame(width: 12)

                    Text(compactCueText)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.quietText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.90)
                        .allowsTightening(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 1)
        .padding(.bottom, 2)
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

                Text("score")
                    .font(DesignTokens.Typography.micro)
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
        HStack(spacing: 6) {
            Image(systemName: "macwindow")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.ColorToken.quietText)

            Text(compactLatestAppLabel)
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.90)
                .allowsTightening(true)

            Text("·")
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(DesignTokens.ColorToken.quietText)

            Text(snapshot.lastUpdated, style: .time)
                .font(DesignTokens.Typography.micro)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .lineLimit(1)

            Spacer(minLength: DesignTokens.Spacing.xs)
            expandButton
        }
        .padding(.horizontal, 2)
    }

    private var compactStateLabel: String {
        switch snapshot.state {
        case .focused:
            return "Focus flow"
        case .assistedDeepWork:
            return "Deep work"
        case .developmentLoop:
            return "Tool loop"
        case .researchFlow:
            return "Research flow"
        case .neutral:
            return "Steady"
        case .passiveDrift:
            return "Passive drift"
        case .compulsiveDrift:
            return "Sticky loop"
        case .overloaded:
            return "Overloaded"
        case .idlePaused:
            return "Paused"
        case .unknown:
            return "Quiet"
        }
    }

    private var compactContextLabel: String {
        switch snapshot.context {
        case .deepWork:
            return "Task rhythm"
        case .assistedWork:
            return "Supported work"
        case .development:
            return "Purposeful switching"
        case .research:
            return "Gathering context"
        case .generalBrowsing:
            return "Browsing"
        case .passiveConsumption:
            return "Passive loop"
        case .audioRegulation:
            return "Audio cue"
        case .paused:
            return "Between actions"
        case .unknown:
            return "Low signal"
        }
    }

    private var compactLatestAppLabel: String {
        snapshot.latestApp.count > 22 ? "Recent app" : snapshot.latestApp
    }

    private var rhythmSourceLabel: String {
        rhythmSourceLabel(for: viewModel.telemetryMode)
    }

    private var rhythmSourceDescription: String {
        rhythmSourceDescription(for: viewModel.telemetryMode)
    }

    private var rhythmSourceColor: Color {
        rhythmSourceColor(for: viewModel.telemetryMode)
    }

    private var signalStatusLabel: String {
        switch snapshot.telemetryStatus {
        case .mocked:
            return "Preview"
        case .live:
            return "Reading"
        case .stale:
            return "Stale"
        case .unavailable:
            return "Unavailable"
        }
    }

    private func rhythmSourceLabel(for mode: TelemetryMode) -> String {
        switch mode {
        case .liveApp:
            return "Now"
        case .mock:
            return "Preview"
        }
    }

    private func rhythmSourceDescription(for mode: TelemetryMode) -> String {
        switch mode {
        case .liveApp:
            return "Using your current active app rhythm."
        case .mock:
            return "Explore Drift states without using your current app."
        }
    }

    private func rhythmSourceColor(for mode: TelemetryMode) -> Color {
        switch mode {
        case .liveApp:
            return DesignTokens.ColorToken.nowMode
        case .mock:
            return DesignTokens.ColorToken.previewMode
        }
    }

    private var compactCueText: String {
        switch snapshot.intervention.kind {
        case .breathingReset:
            return "Breathing cue · one breath"
        case .softPause:
            return "Soft pause"
        case .reflectivePrompt:
            return "Intention · choose next"
        case .rhythmTransitionSuggestion:
            return compactRhythmCueText
        case .none:
            return compactRhythmCueText
        }
    }

    private var compactRhythmCueText: String {
        switch snapshot.rhythmPlan.mode {
        case .deepWorkRhythm:
            return "Focus flow · steady"
        case .risingEnergyRhythm:
            return "Rising energy · gentle lift"
        case .downshiftRhythm:
            return "Downshift · softer rhythm"
        case .windDownRhythm:
            return "Wind-down · lower pace"
        case .startUpRhythm:
            return "Start-up · light momentum"
        case .visualBreathingCue:
            return "Breathing cue · one breath"
        case .none:
            switch snapshot.state {
            case .focused, .assistedDeepWork, .developmentLoop, .researchFlow:
                return "Steady rhythm"
            case .idlePaused:
                return "Paused · re-enter gently"
            case .unknown:
                return "No cue needed"
            default:
                return "No cue needed"
            }
        }
    }

    private var compactCueIcon: String {
        switch snapshot.intervention.kind {
        case .breathingReset:
            return "lungs.fill"
        case .rhythmTransitionSuggestion:
            return "waveform"
        case .softPause:
            return "pause.fill"
        case .reflectivePrompt:
            return "arrow.turn.down.right"
        case .none:
            return "waveform"
        }
    }

    private var learnMoreCopy: LearnMoreCopy {
        LearnMoreCopy.copy(for: snapshot.state)
    }

    private var expandedDetail: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Divider()
                    .overlay(DesignTokens.ColorToken.quietBorder)

                if isShowingLearnMore {
                    learnMorePanel
                } else {
                    detailCard("Rhythm Source") {
                        rhythmSourceDetail
                    }

                    detailCard("Suggested Rhythm") {
                        suggestedRhythmDetail
                    }

                    detailCard("Visual Ambience") {
                        visualAmbienceDetail
                    }

                    detailCard("Local Soundscape") {
                        localCueDetail
                    }

                    detailCard("Apple Music") {
                        appleMusicDetail
                    }

                    detailCard("Cue") {
                        interventionDetail
                    }

                    detailCard("Learn More") {
                        learnMoreEntry
                    }

                    detailCard("Privacy") {
                        privacySummary
                    }

                    detailCard("System") {
                        systemSummary
                    }
                }
            }
            .padding(.top, DesignTokens.Spacing.xs)
        }
        .frame(maxHeight: DesignTokens.Layout.expandedDetailMaxHeight)
        .clipped()
        .onAppear {
            viewModel.openSuggestedBreathingOrbIfNeeded()
        }
    }

    private var rhythmSourceDetail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .center, spacing: DesignTokens.Spacing.sm) {
                Picker(
                    "Rhythm source",
                    selection: Binding(
                        get: { viewModel.telemetryMode },
                        set: { viewModel.setTelemetryMode($0) }
                    )
                ) {
                    ForEach([TelemetryMode.liveApp, .mock]) { mode in
                        Text(rhythmSourceLabel(for: mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 148)
                .hudHoverLift(accent: rhythmSourceColor, scale: 1.0)

                Spacer(minLength: DesignTokens.Spacing.xs)

                if viewModel.telemetryMode == .mock {
                    Button {
                        viewModel.advanceSnapshot()
                    } label: {
                        Label("Next state", systemImage: "forward.end.fill")
                            .labelStyle(.titleAndIcon)
                            .font(DesignTokens.Typography.caption)
                            .lineLimit(1)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(rhythmSourceColor.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(rhythmSourceColor.opacity(0.24), lineWidth: 1)
                    )
                    .help("Next state")
                    .hudHoverLift(accent: rhythmSourceColor, scale: 1.0)
                }
            }

            Text(rhythmSourceDescription)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DesignTokens.Spacing.xs) {
                detailPill(compactStateLabel, color: accent)
                detailPill(signalStatusLabel, color: rhythmSourceColor)
            }
        }
    }

    private var suggestedRhythmDetail: some View {
        let plan = snapshot.rhythmPlan

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                rhythmChip(plan.displayName)
                rhythmChip(plan.intensity.displayName)
            }

            Text(compactCueText)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)

            Text(viewModel.rhythmStatus)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 3) {
                detailRow("Feel", plan.texture.displayName)
                detailRow("Pace", plan.cadence)
            }
        }
    }

    private var visualAmbienceDetail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                Text("Where would you like a seat?")
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)

                Spacer(minLength: DesignTokens.Spacing.xs)

                Text("Suggested: \(viewModel.recommendedAmbiencePreset.title)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(viewModel.recommendedAmbiencePreset.tint.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }

            LazyVGrid(columns: ambienceGridColumns, alignment: .leading, spacing: 6) {
                ForEach(viewModel.visibleAmbiencePresets) { preset in
                    ambiencePresetChip(preset)
                }
            }

            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
                    .frame(width: 12)

                Text("Local preview. Applied only when you choose.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
            }

            if let statusMessage = viewModel.ambienceStatusMessage {
                Text(statusMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.canApplyAmbience {
                capsuleButton("Apply ambience") {
                    viewModel.applyAmbience()
                }
            }
        }
    }

    private var ambienceGridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 0), spacing: 6),
            GridItem(.flexible(minimum: 0), spacing: 6)
        ]
    }

    private func ambiencePresetChip(_ preset: VisualAmbiencePreset) -> some View {
        let isSelected = viewModel.selectedAmbiencePreset?.id == preset.id
        let isRecommended = viewModel.recommendedAmbiencePreset.id == preset.id
        let tint = preset.tint.color

        return Button {
            viewModel.selectAmbiencePreset(preset)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(tint)
                        .frame(width: 8, height: 8)

                    Text(preset.title)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)

                    Spacer(minLength: 0)

                    if isRecommended {
                        Image(systemName: "sparkle")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(tint)
                    }
                }

                Text(preset.subtitle)
                    .font(DesignTokens.Typography.micro)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .frame(height: 52, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(isSelected ? 0.18 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.pill, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.pill, style: .continuous)
                    .strokeBorder(tint.opacity(isSelected ? 0.54 : 0.20), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(preset.cognitiveIntent)
        .hudHoverLift(accent: tint, scale: 1.0)
    }

    private var localCueDetail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            detailRow("Cue", viewModel.suggestedSoundscapeMode.displayName)

            if let availabilityMessage = viewModel.suggestedSoundscapeAvailabilityMessage {
                Text(availabilityMessage)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: DesignTokens.Spacing.xs) {
                capsuleButton("Play local cue", isDisabled: !viewModel.isSuggestedSoundscapeAvailable) {
                    viewModel.playSuggestedSoundscape()
                }

                capsuleButton("Stop", isDisabled: !viewModel.soundscapePlaybackState.isActive) {
                    viewModel.stopSoundscape()
                }
            }

            capsuleButton("Play breathing cue") {
                viewModel.playBreathingCue()
            }

            Text(viewModel.soundscapePlaybackStatus)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("Local cues stay on this Mac.")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
        }
    }

    private var privacySummary: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 24, height: 24)
                .background(accent.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Your rhythm stays on this Mac.")
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)

                Text("Drift processes attention state locally and does not collect private content.")
                    .font(DesignTokens.Typography.intervention)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Apple Music is optional and only opens when you choose.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
                    .lineLimit(2)
            }
        }
    }

    private var systemSummary: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            detailRow("Latest", snapshot.latestApp)
            detailRow("Updated", DateFormatter.localizedString(from: snapshot.lastUpdated, dateStyle: .none, timeStyle: .short))

            Text("Buffer \(viewModel.bufferSizeDescription)")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.ColorToken.quietText)
                .lineLimit(1)
        }
    }

    private var learnMoreEntry: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                isShowingLearnMore = true
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "info.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Learn More")
                        .font(DesignTokens.Typography.metric)
                        .foregroundStyle(DesignTokens.ColorToken.primaryText)

                    Text("This state, cue, and privacy.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: DesignTokens.Spacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.ColorToken.quietText)
            }
        }
        .buttonStyle(.plain)
    }

    private var learnMorePanel: some View {
        let copy = learnMoreCopy

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isShowingLearnMore = false
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(DesignTokens.ColorToken.panelBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .hudHoverLift(accent: accent, scale: 1.02)

            detailCard("Attention") {
                learnMoreSection(
                    title: compactStateLabel,
                    body: copy.meaning,
                    systemImage: "circle.dotted"
                )
            }

            detailCard("Cue") {
                learnMoreSection(
                    title: compactCueText,
                    body: copy.cue,
                    systemImage: compactCueIcon
                )
            }

            detailCard("Why") {
                learnMoreSection(
                    title: "Cognitive psychology",
                    body: copy.science,
                    systemImage: "brain.head.profile"
                )
            }

            privacyLockSection
        }
    }

    private func learnMoreSection(
        title: String,
        body: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DesignTokens.Typography.metric)
                    .foregroundStyle(DesignTokens.ColorToken.primaryText)
                    .lineLimit(1)

                Text(body)
                    .font(DesignTokens.Typography.intervention)
                    .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var privacyLockSection: some View {
        detailCard("Privacy") {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.11))

                    Image(systemName: "lock.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Your rhythm stays on this Mac.")
                        .font(DesignTokens.Typography.metric)
                        .foregroundStyle(DesignTokens.ColorToken.primaryText)

                    Text("Drift uses local signals like active app changes and coarse rhythm patterns. It does not collect private content or device inputs.")
                        .font(DesignTokens.Typography.intervention)
                        .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Apple does not receive Drift's attention state. Drift does not upload it.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.quietText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Apple Music is optional and only opens when you choose.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.quietText)
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
                    .lineLimit(2)
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

            breathingResetControl
        }
    }

    private var appleMusicDetail: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(viewModel.appleMusicStatusLabel)
                .font(DesignTokens.Typography.metric)
                .foregroundStyle(DesignTokens.ColorToken.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(viewModel.appleMusicDetailMessage)
                .font(DesignTokens.Typography.intervention)
                .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                .lineLimit(2)
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

    private func detailPill(_ value: String, color: Color) -> some View {
        Text(value)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.22), lineWidth: 1)
            )
    }

    private var breathingResetControl: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            if viewModel.isBreathingResetActive {
                BreathingOrbView(
                    phase: viewModel.breathingPhase,
                    accent: accent,
                    onDismiss: viewModel.dismissBreathingReset
                )
            } else {
                capsuleButton("Breathing reset") {
                    viewModel.startBreathingReset()
                }
            }
        }
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
        let sourceColor = rhythmSourceColor

        return Button {
            isShowingModeChooser.toggle()
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(sourceColor.opacity(0.18))
                        .frame(width: 13, height: 13)

                    Circle()
                        .fill(sourceColor)
                        .frame(width: 6, height: 6)
                }

                Text(rhythmSourceLabel)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(sourceColor)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(sourceColor.opacity(0.72))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
            .background(sourceColor.opacity(0.08), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(sourceColor.opacity(0.26), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Switch rhythm source")
        .popover(isPresented: $isShowingModeChooser, arrowEdge: .top) {
            modeChooser
        }
        .hudHoverLift(accent: sourceColor, scale: 1.0)
    }

    private var modeChooser: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            modeChoiceButton(.liveApp)
            modeChoiceButton(.mock)
        }
        .padding(DesignTokens.Spacing.sm)
        .frame(width: 210)
    }

    private func modeChoiceButton(_ mode: TelemetryMode) -> some View {
        let isSelected = viewModel.telemetryMode == mode
        let sourceColor = rhythmSourceColor(for: mode)

        return Button {
            viewModel.setTelemetryMode(mode)
            isShowingModeChooser = false
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(sourceColor)
                    .frame(width: 7, height: 7)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(rhythmSourceLabel(for: mode))
                        .font(DesignTokens.Typography.metric)
                        .foregroundStyle(DesignTokens.ColorToken.primaryText)
                        .lineLimit(1)

                    Text(rhythmSourceDescription(for: mode))
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.ColorToken.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: DesignTokens.Spacing.xs)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(sourceColor)
                        .padding(.top, 3)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(isSelected ? sourceColor.opacity(0.10) : DesignTokens.ColorToken.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.innerCard, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var expandButton: some View {
        Button {
            toggleExpanded()
        } label: {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .semibold))
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
        .help(isExpanded ? "Collapse" : "Expand")
        .hudCircularHoverGlow(accent: accent)
    }

    private var liquidPanelFill: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DesignTokens.ColorToken.liquidGlassTop,
                        DesignTokens.ColorToken.liquidGlassMid,
                        DesignTokens.ColorToken.liquidGlassBottom
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var glassHighlight: some View {
        RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        DesignTokens.ColorToken.glassSheen,
                        DesignTokens.ColorToken.glassReflection,
                        DesignTokens.ColorToken.hairlineBorder
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
            .allowsHitTesting(false)
    }

    private func toggleExpanded() {
        var transaction = Transaction(animation: .easeInOut(duration: 0.16))
        transaction.disablesAnimations = false

        withTransaction(transaction) {
            isExpanded.toggle()
            if !isExpanded {
                isShowingLearnMore = false
            }
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

private struct LearnMoreCopy {
    let meaning: String
    let science: String
    let cue: String

    static func copy(for state: AttentionState) -> LearnMoreCopy {
        switch state {
        case .focused:
            return LearnMoreCopy(
                meaning: "Your rhythm looks steady.",
                science: "Stable context and low switching support sustained attention.",
                cue: "Drift stays quiet when your rhythm is already working."
            )
        case .assistedDeepWork, .developmentLoop:
            return LearnMoreCopy(
                meaning: "You seem to be moving through a purposeful tool loop.",
                science: "Switching can be useful when tools support the same goal.",
                cue: "Drift avoids treating purposeful tool-switching as distraction."
            )
        case .researchFlow:
            return LearnMoreCopy(
                meaning: "Your rhythm looks steady.",
                science: "Stable context and low switching support sustained attention.",
                cue: "Drift stays quiet when your rhythm is already working."
            )
        case .neutral:
            return LearnMoreCopy(
                meaning: "The signal looks mixed, so Drift stays light.",
                science: "When context is unclear, quiet feedback is less distracting than a strong read.",
                cue: "No strong suggestion right now."
            )
        case .passiveDrift:
            return LearnMoreCopy(
                meaning: "Your rhythm may be becoming more automatic.",
                science: "Passive loops can reduce intentional control without feeling disruptive.",
                cue: "A small intention helps you choose what comes next."
            )
        case .compulsiveDrift:
            return LearnMoreCopy(
                meaning: "The pattern looks sticky or repetitive.",
                science: "Fast repeated loops can make stopping harder.",
                cue: "A soft pause creates space without forcing you to stop."
            )
        case .overloaded:
            return LearnMoreCopy(
                meaning: "Your digital rhythm looks crowded.",
                science: "High switching and weak context can increase cognitive load.",
                cue: "A breathing cue can lower stimulation before the next action."
            )
        case .idlePaused:
            return LearnMoreCopy(
                meaning: "You seem between states.",
                science: "Transitions are useful moments to choose direction.",
                cue: "Drift can help you re-enter gently."
            )
        case .unknown:
            return LearnMoreCopy(
                meaning: "Drift does not have enough signal yet.",
                science: "It is better to stay quiet than over-interpret weak data.",
                cue: "No strong suggestion right now."
            )
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
                                Color.white.opacity(isHovered ? 0.13 : 0.09),
                                DesignTokens.ColorToken.elevatedPanelBackground,
                                Color.black.opacity(0.03)
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
                color: isHovered ? accent.opacity(0.11) : .black.opacity(0.09),
                radius: isHovered ? 10 : 5,
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
