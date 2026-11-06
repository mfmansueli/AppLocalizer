//
//  GuidedReviewPreview.swift
//  AppLocalizer
//

import SwiftUI

/// The App Preview in Review & push: playing with sound, what it is and
/// its music, and, while it's watched, what to ask the design source.
struct GuidedReviewPreview: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        let isWatching = run.stage == .watchPreview && run.watchesAppPreview
        if let file = studio.watchedPreview {
            HStack(alignment: .top, spacing: Spacing.large) {
                StudioAppPreviewPlayer(studio: studio, file: file, width: file.displayType == .iPad ? 260 : 206)
                    .fixedSize()
                VStack(alignment: .leading, spacing: Spacing.small) {
                    AutopilotWatchInfoBox(studio: studio, file: file, isEditable: isWatching && run.previewReview?.isBusy != true)
                    if isWatching {
                        AutopilotWatchAskBox(studio: studio, run: run, isEditable: true)
                    } else {
                        Text("Plays with sound here; muted on repeat on the App Store.")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.medium)
            .modifier(GuidedSelectableCard(padding: 0))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("autopilot.guided.review.appPreview")
        } else {
            HStack(spacing: Spacing.small) {
                ProgressView().controlSize(.small)
                Text("Opening the App Preview…").foregroundStyle(Palette.label2)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .modifier(GuidedSelectableCard(padding: 0))
        }
    }
}
