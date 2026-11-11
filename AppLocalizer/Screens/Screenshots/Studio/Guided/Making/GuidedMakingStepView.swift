//
//  GuidedMakingStepView.swift
//  AppLocalizer
//

import SwiftUI

/// Step 4, Making it: what Autopilot is doing, how far along and about
/// how long is left, the captures as they arrive, the looks as they're
/// designed, the check of every image, what it fixed on its own, the
/// person's next stop, and the details. Pick, when the person asked to
/// pick the captures, is its own page.
struct GuidedMakingStepView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun
    let assistant: String?
    /// This Mac's simulators, from the environment: the studio's
    /// `launcher` is set only once the sheet appears, after this reads it.
    @Environment(ClaudeCodeLauncher.self) private var launcher: ClaudeCodeLauncher?

    var body: some View {
        if run.stage == .pick {
            AutopilotPickStageView(studio: studio, run: run, isEditable: true)
        } else {
            let simulators = launcher?.simulators
            TimelineView(.periodic(from: .now, by: 30)) { context in
                content(GuidedRunProgress.make(run, now: context.date))
            }
            .task(id: run.id) {
                if let simulators { await studio.checkDevicesDuringRun(on: simulators) }
            }
            .task(id: studio.simulatorFaultKey) {
                // No simulator starts on this Mac: AppLocalizer repairs
                // what it can and tries the devices again, by itself.
                guard let simulators, !studio.simulatorFaultKey.isEmpty else { return }
                await studio.repairSimulators(on: simulators)
            }
            .task(id: studio.watchesDuo(on: simulators)) {
                // iPhone Duo is started and opened before the assistant
                // gets to it, and kept so while its screens are left.
                guard let simulators, studio.watchesDuo(on: simulators) else { return }
                await studio.watchDuo(on: simulators)
            }
        }
    }

    private func content(_ progress: GuidedRunProgress) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(progress.title)
                        .font(.title2.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("autopilot.guided.title")
                    ProgressView(value: progress.fraction)
                        .accessibilityLabel(Text(progress.title))
                        .accessibilityValue(Text("\(Int((progress.fraction * 100).rounded())) percent"))
                        .accessibilityIdentifier("autopilot.guided.making.progress")
                    Text(progress.line)
                        .font(.callout)
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.guided.making.line")
                }
                let rows = GuidedPlanTimeline.rows(
                    plan: run.plan, client: run.clientName(assistant: assistant), design: run.designKind,
                    brand: studio.shotStyleBrand, kept: run.capturesKeptAtStart,
                    gaps: run.interfaceGaps ?? [], app: studio.app.name
                )
                GuidedLiveTimelineView(rows: rows, states: GuidedLiveTimeline.states(of: rows, run: run))
                stage
                if fixedCount > 0 {
                    Label {
                        Text(fixedCount == 1
                            ? String(localized: "Autopilot fixed 1 problem on its own. You’ll see it in the review.")
                            : String(localized: "Autopilot fixed \(fixedCount) problems on its own. You’ll see them in the review."))
                    } icon: {
                        Image(systemName: "checkmark")
                    }
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .accessibilityIdentifier("autopilot.guided.making.fixed")
                }
                Text(GuidedNextStop.line(for: run, progress: progress))
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .accessibilityIdentifier("autopilot.guided.making.next")
                details
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
    }

    /// Problems a later capture fixed without the person.
    private var fixedCount: Int { run.problems.count { $0.resolution == .captured } }

    @ViewBuilder
    private var stage: some View {
        switch run.stage {
        case .waiting:
            AutopilotWaitStageView(studio: studio, client: assistant)
                .modifier(GuidedSelectableCard(padding: 0))
        case .capture:
            AutopilotAssistantStatus(studio: studio, run: run)
            ForEach(run.problemGroups) { group in
                AutopilotProblemCard(studio: studio, run: run, group: group)
            }
            if !run.skippedRecordings.isEmpty {
                GuidedSkippedRecordingsCard(studio: studio, skips: run.skippedRecordings)
            }
            arriving
        case .design:
            if let revision = run.revision {
                Label("Asked for changes: “\(revision.note)”", systemImage: "arrow.uturn.backward")
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("autopilot.guided.making.revision")
            }
            AutopilotAssistantStatus(studio: studio, run: run)
            if run.hasDirections {
                GuidedDesignCards(studio: studio, run: run)
            }
            if run.usesConcepts {
                AutopilotConceptsBox(studio: studio, run: run)
            }
        case .localize:
            let card = GuidedLocalizeCard.make(run, client: run.clientName(assistant: assistant))
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(card.title).font(.callout.weight(.semibold))
                Text(card.detail)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(GuidedSelectableCard())
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("autopilot.guided.making.checking")
        default:
            EmptyView()
        }
    }

    /// The latest captures, newest first.
    @ViewBuilder
    private var arriving: some View {
        if !run.captures.isEmpty {
            let captures = Array(run.captures.suffix(8).reversed())
            // As tall as the tallest capture shown, so landscape and iPad
            // captures don't sit under a band of empty card.
            let height = min(152, captures.map { thumbnailWidth($0) * aspect($0) }.max() ?? 152)
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Arriving").font(.callout.weight(.semibold))
                ScrollView(.horizontal) {
                    HStack(alignment: .bottom, spacing: Spacing.small) {
                        ForEach(captures) { capture in
                            StudioShotImage(
                                image: studio.image(for: capture, width: 160),
                                width: thumbnailWidth(capture),
                                aspect: aspect(capture),
                                cornerFraction: capture.target.displayType == .watch ? 0.24 : 0.05
                            )
                            .frame(height: height, alignment: .bottom)
                        }
                    }
                }
                .frame(height: height)
            }
            .modifier(GuidedSelectableCard())
            .accessibilityElement(children: .ignore)
            // The plan's, as the progress line counts them: every capture
            // kept said 294 beside "168 of 224" (iPad, Watch and retakes).
            .accessibilityLabel(Text("\(run.capturedCount) of \(run.totalCaptures) captures so far"))
            .accessibilityIdentifier("autopilot.guided.making.arriving")
        }
    }

    /// Thumbnails share a height: a landscape capture is wider than a
    /// phone's.
    static func thumbnailWidth(for display: ScreenshotDisplayType, pixelSize: PixelSize) -> CGFloat {
        let height: CGFloat = display == .watch ? 48 : 96
        guard pixelSize.width > 0, pixelSize.height > 0 else { return 44 }
        return min(88, (height * CGFloat(pixelSize.width) / CGFloat(pixelSize.height)).rounded())
    }

    private func thumbnailWidth(_ capture: AutopilotCapture) -> CGFloat {
        Self.thumbnailWidth(for: capture.target.displayType, pixelSize: capture.pixelSize) * 0.8
    }

    private func aspect(_ capture: AutopilotCapture) -> Double {
        Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1))
    }

    @ViewBuilder
    private var details: some View {
        let entries = run.log
        if !entries.isEmpty {
            Button(studio.guided.showsDetails ? String(localized: "Hide details") : String(localized: "Show details (\(entries.count))")) {
                studio.guided.showsDetails.toggle()
            }
            .buttonStyle(.link)
            .font(.callout)
            .accessibilityIdentifier("autopilot.guided.making.details")
            if studio.guided.showsDetails {
                AutopilotLogView(entries: Array(entries.suffix(20)))
            }
        }
    }
}
