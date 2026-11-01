//
//  AutopilotCaptureStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Capture: progress, the latest capture in a device frame, the problems
/// the person has to answer (one card per cause), the assistant's log and
/// the captures so far.
struct AutopilotCaptureStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Capture").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("\(run.capturedCount) of \(run.totalCaptures)")
                        .monospacedDigit()
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("autopilot.capture.count")
                }
                ProgressView(value: Double(run.capturedCount), total: Double(max(run.totalCaptures, 1)))
                    .accessibilityLabel(Text("Captured \(run.capturedCount) of \(run.totalCaptures)"))
                HStack(alignment: .top, spacing: Spacing.large) {
                    latest
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        if let launched = studio.launchedRun, launched.isActive || launched.failure != nil || !launched.denials.isEmpty {
                            AutopilotLaunchStatus(studio: studio, run: launched)
                        }
                        ForEach(run.problemGroups) { group in
                            AutopilotProblemCard(studio: studio, run: run, group: group)
                        }
                        AutopilotLogView(entries: Array(run.log.suffix(8)))
                        thumbnails
                    }
                }
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.capture")
    }

    private var latest: some View {
        VStack(spacing: Spacing.xSmall) {
            let capture = run.latestCapture
            let display = capture?.target.displayType ?? .iPhone
            AutopilotSimulatorFrame(
                display: display,
                image: studio.image(for: capture, width: display == .visionPro ? 480 : 360),
                pixelSize: capture?.pixelSize ?? display.defaultPixelSize
            )
            if let capture {
                Text(place(of: capture.target))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("autopilot.capture.latest")
            }
        }
    }

    private var thumbnails: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Spacing.xSmall) {
                ForEach(run.captures.suffix(12).reversed()) { capture in
                    VStack(spacing: 2) {
                        StudioShotImage(
                            image: studio.image(for: capture, width: 120),
                            width: Self.thumbnailWidth(for: capture.target.displayType, pixelSize: capture.pixelSize),
                            aspect: Double(capture.pixelSize.height) / Double(max(capture.pixelSize.width, 1)),
                            cornerFraction: capture.target.displayType == .watch ? 0.24 : 0.05
                        )
                        Text(capture.target.locale.split(separator: "-").first.map(String.init) ?? capture.target.locale)
                            .font(.caption2)
                            .foregroundStyle(Palette.label2)
                    }
                }
            }
        }
        .accessibilityLabel(Text("\(run.captures.count) captures"))
    }

    /// Thumbnails share a height: a landscape capture is wider than a
    /// phone's.
    static func thumbnailWidth(for display: ScreenshotDisplayType, pixelSize: PixelSize) -> CGFloat {
        let height: CGFloat = display == .watch ? 48 : 96
        guard pixelSize.width > 0, pixelSize.height > 0 else { return 44 }
        return min(88, (height * CGFloat(pixelSize.width) / CGFloat(pixelSize.height)).rounded())
    }

    /// "German · iPad 13″ · Week".
    private func place(of target: AutopilotCaptureTarget) -> String {
        [
            StoreLocaleCatalog.locale(code: target.locale)?.shortName ?? target.locale,
            target.displayType.title,
            run.plan.screen(id: target.screenID)?.name ?? target.screenID,
        ].joined(separator: " · ")
    }
}
