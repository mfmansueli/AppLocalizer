//
//  ScreenshotReviewNotes.swift
//  AppLocalizer
//

import SwiftUI

/// What review says under the screenshot groups: renders that fail a check
/// and aren't here (Show in Captions), renders waiting for a localization,
/// images discarded (Undo), and apps whose screenshots couldn't be read.
struct ScreenshotReviewNotes: View {
    let viewModel: ReviewPushViewModel
    let onShowInCaptions: (ScreenshotPlanExclusion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            if let first = viewModel.failedRenders.first {
                Banner(kind: .partialFailure, title: failedText) {
                    Button("Show in Captions") { onShowInCaptions(first) }
                        .accessibilityIdentifier("review.shots.showInCaptions")
                }
                .padding(.horizontal, -Spacing.large)
                .accessibilityIdentifier("review.shots.failed")
            }
            if !viewModel.unlocalizedRenders.isEmpty {
                Banner(kind: .warning, title: unlocalizedTitle, message: unlocalizedMessage)
                    .padding(.horizontal, -Spacing.large)
                    .accessibilityIdentifier("review.shots.unlocalized")
            }
            let kept = viewModel.keptImages.count
            if kept > 0 {
                HStack(spacing: Spacing.xSmall) {
                    Text(kept == 1
                        ? String(localized: "1 image discarded: the live screenshot stays.")
                        : String(localized: "\(kept) images discarded: the live screenshots stay."))
                        .accessibilityIdentifier("review.shots.held")
                    Button("Undo") {
                        Task { await viewModel.undoImageDiscards() }
                    }
                    .buttonStyle(.link)
                    .accessibilityIdentifier("review.shots.undo")
                }
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xxSmall)
            }
            ForEach(errors, id: \.appID) { error in
                Banner(kind: .apiError, title: String(localized: "Couldn’t check \(error.appName)’s screenshots"), message: error.message)
                    .padding(.horizontal, -Spacing.large)
            }
        }
    }

    /// "2 renders fail their checks and aren't here: German iPhone slot 3
    /// (Overflow), German iPad slot 3 (Overflow)."
    private var failedText: String {
        let failed = viewModel.failedRenders
        let names = failed.prefix(2).map(\.title).joined(separator: ", ") + (failed.count > 2 ? ", …" : ".")
        return failed.count == 1
            ? String(localized: "1 render fails its check and isn’t here: \(names)")
            : String(localized: "\(failed.count) renders fail their checks and aren’t here: \(names)")
    }

    private var unlocalizedTitle: String {
        let count = viewModel.unlocalizedRenders.count
        return count == 1
            ? String(localized: "1 render waits for a localization App Store Connect doesn’t have yet.")
            : String(localized: "\(count) renders wait for localizations App Store Connect doesn’t have yet.")
    }

    private var unlocalizedMessage: String {
        var seen: Set<String> = []
        let names = viewModel.unlocalizedRenders.map(\.localeName).filter { seen.insert($0).inserted }
        return String(localized: "Add \(names.formatted(.list(type: .and))) to the version in App Store Connect, then refresh.")
    }

    private var errors: [(appID: StoreApp.ID, appName: String, message: String)] {
        viewModel.screenshots.loadErrors
            .filter { appID, _ in viewModel.scope == .allApps || appID == viewModel.selectedAppID }
            .map { appID, message in (appID, viewModel.screenshots.apps[appID]?.name ?? appID, message) }
            .sorted { $0.appName < $1.appName }
    }
}
