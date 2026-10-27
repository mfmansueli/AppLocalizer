//
//  ScreenshotReviewContent.swift
//  AppLocalizer
//

import SwiftUI

/// The screenshot part of Review & Push, under the text changes: what a
/// restore queued, each app's sets, then the notes.
struct ScreenshotReviewContent: View {
    let viewModel: ReviewPushViewModel
    let onShowInCaptions: (ScreenshotPlanExclusion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if let notice = viewModel.screenshots.notice {
                Banner(kind: .info, title: notice) {
                    Button {
                        viewModel.screenshots.notice = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(Text("Dismiss"))
                }
                .padding(.horizontal, -Spacing.large)
                .accessibilityIdentifier("review.shots.notice")
            }
            ForEach(viewModel.screenshotPlans.filter { !$0.groups.isEmpty }, id: \.appID) { plan in
                ScreenshotReviewSection(plan: plan, viewModel: viewModel)
            }
            if viewModel.screenshots.isLoading, !viewModel.showsScreenshots {
                HStack(spacing: Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking screenshots against App Store Connect…")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .padding(.horizontal, Spacing.small)
                .accessibilityIdentifier("review.shots.loading")
            }
            ScreenshotReviewNotes(viewModel: viewModel, onShowInCaptions: onShowInCaptions)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.shots")
    }

    /// Whether there's anything to show at all.
    static func hasContent(_ viewModel: ReviewPushViewModel) -> Bool {
        viewModel.showsScreenshots || viewModel.screenshots.notice != nil
            || !viewModel.screenshots.loadErrors.isEmpty || viewModel.screenshots.isLoading
    }
}
