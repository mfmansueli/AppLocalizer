//
//  GuidedSkippedRecordingsCard.swift
//  AppLocalizer
//

import SwiftUI

/// The App Preview's recordings the assistant couldn't make, and why, with
/// Record Again. MB Admin's run left both out (a refused command) and said
/// so only in the details, so the App Preview would have quietly been
/// missing.
struct GuidedSkippedRecordingsCard: View {
    @Bindable var studio: ScreenshotStudioModel
    let skips: [AutopilotRecordingSkip]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Label {
                Text(title).font(.callout.weight(.semibold))
            } icon: {
                Image(systemName: "video.slash")
            }
            if let reason = skips.last?.reason, !reason.isEmpty {
                Text(reason)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            Button("Record Again") { studio.recordAgain() }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.small)
                .accessibilityIdentifier("autopilot.guided.making.recordAgain")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GuidedSelectableCard())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.making.skippedRecordings")
    }

    /// "App Preview: iPhone 6.9″ and iPad 13″ weren’t recorded".
    private var title: String {
        let skipped = Set(skips.map(\.target.displayType))
        let displays = ScreenshotDisplayType.studio.filter(skipped.contains)
        let devices = displays.map(\.title).formatted(.list(type: .and))
        return displays.count == 1
            ? String(localized: "App Preview: \(devices) wasn’t recorded")
            : String(localized: "App Preview: \(devices) weren’t recorded")
    }
}
