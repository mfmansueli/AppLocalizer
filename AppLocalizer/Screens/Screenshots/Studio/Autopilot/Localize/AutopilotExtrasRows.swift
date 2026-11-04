//
//  AutopilotExtrasRows.swift
//  AppLocalizer
//

import SwiftUI

/// Localize and check's rows for the extras, under the languages: the
/// header and search artwork rendered with each placement's text and
/// checked in every language (pills and a line, like a screenshot's
/// checks: errors keep that image out of the push), and the App Previews
/// assembled from the recordings. They're made once every caption fits.
struct AutopilotExtrasRows: View {
    let run: AutopilotRun

    var body: some View {
        if !run.plan.artworkKinds.isEmpty {
            Divider()
            row(
                title: run.plan.alsoMakes.artworkSize.placeTitle,
                detail: artworkDetail, state: artworkState, identifier: "autopilot.localize.artwork",
                checks: progress?.isArtworkDone == true ? progress?.artworkChecks ?? [] : []
            )
        }
        if !run.plan.previewDisplays.isEmpty {
            Divider()
            row(title: String(localized: "App Preview"), detail: previewDetail, state: previewState, identifier: "autopilot.localize.appPreview")
        }
    }

    private enum RowState { case waiting, working, done, problem }

    private var progress: AutopilotExtrasProgress? { run.extrasProgress }

    private var languages: Int { run.plan.localeCodes.count }

    private var artworkState: RowState {
        guard let progress else { return .waiting }
        if !progress.isArtworkDone { return .working }
        let hasErrors = progress.artworkChecks?.contains(where: \.isError) == true
        return progress.artworkTooLong.isEmpty && !hasErrors ? .done : .problem
    }

    private var artworkDetail: String {
        guard let progress else { return String(localized: "Made with each language’s caption once they all fit") }
        guard progress.isArtworkDone else {
            return String(localized: "Rendering with each language’s caption · \(progress.artworkDone) of \(languages)")
        }
        guard !progress.artworkTooLong.isEmpty else {
            let fits = String(localized: "Rendered in \(languages) languages · headline fits in all")
            return run.plan.alsoMakes.artworkMotion == .loop ? fits + String(localized: " · loops seamlessly · 30 fps") : fits
        }
        let names = progress.artworkTooLong.map { StoreLocaleCatalog.locale(code: $0)?.name ?? $0 }
        return String(localized: "Rendered in \(languages) languages · headline too long in \(names.formatted(.list(type: .and)))")
    }

    private var previewState: RowState {
        guard let progress, progress.isArtworkDone else { return .waiting }
        if !progress.arePreviewsDone { return .working }
        return progress.previewProblems.isEmpty ? .done : .problem
    }

    /// "Assembling 15 videos from each language’s recording · 0:24 · ♫ Warm
    /// acoustic · 886 × 1920 and 1200 × 1600 · 30 fps", or "English (U.S.)
    /// · 0:24 · …". The length is the picked moments' until it's assembled.
    private var previewDetail: String {
        if let problem = progress?.previewProblems.first, progress?.arePreviewsDone == true {
            return problem
        }
        let planned = run.hasRecordingMoments ? Double(run.pickedPreviewSeconds) : Double(AutopilotExtras.previewSeconds)
        let length = ExtrasPreviewFile.lengthTitle(progress?.previewSeconds ?? planned)
        let sizes = run.plan.previewDisplays.compactMap { AppPreviewSpec.spec(for: $0, landscape: false)?.pixelSize.title }
        let music = "♫ " + run.plan.alsoMakes.previewMusic.title
        let facts = [length, music, sizes.formatted(.list(type: .and)), "30 fps"].joined(separator: " · ")
        if run.plan.alsoMakes.previewLanguages == .all {
            let count = run.plan.previewLocales.count
            return String(localized: "Assembling \(count) videos from each language’s recording · \(facts)")
        }
        let name = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.name ?? run.plan.primaryLocale
        return "\(name) · \(facts)"
    }

    private func row(title: String, detail: String, state: RowState, identifier: String, checks: [ArtworkCheck] = []) -> some View {
        HStack(alignment: checks.isEmpty ? .center : .top, spacing: Spacing.medium) {
            Text(title)
                .frame(width: 170, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(state == .done ? Palette.label : Palette.label2)
                ArtworkCheckPills(checks: checks, lineCount: 2)
                    .accessibilityIdentifier("\(identifier).checks")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                switch state {
                case .waiting: EmptyView()
                case .working: ProgressView().controlSize(.mini)
                case .done: Image(systemName: "checkmark").foregroundStyle(Palette.positive)
                case .problem: Image(systemName: "exclamationmark.triangle").foregroundStyle(Palette.label2)
                }
            }
            .frame(width: 18)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
