//
//  AutopilotLocalizeStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Localize and check: how many screenshots are ready, what's happening
/// now (AppLocalizer checking a language, or the assistant translating or
/// shortening captions), who's working on them and what it's doing (or why
/// nobody is, with Continue), each language as AppLocalizer renders and
/// checks it, and the log. For the header and search only: their
/// headlines and the artwork, not the screenshots.
struct AutopilotLocalizeStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Localize and check")
                            .font(.title3.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(countText)
                            .monospacedDigit()
                            .foregroundStyle(Palette.label2)
                            .accessibilityIdentifier("autopilot.localize.count")
                    }
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                    .accessibilityLabel(Text(countText))
                if let now = happeningNow {
                    HStack(spacing: Spacing.small) {
                        ProgressView().controlSize(.small)
                        Text(now).font(.callout.weight(.medium))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("autopilot.localize.now")
                }
                AutopilotAssistantStatus(studio: studio, run: run, launchNote: launchNote)
                VStack(spacing: 0) {
                    if isExtrasOnly {
                        if !run.plan.artworkKinds.isEmpty { headlinesRow }
                    } else {
                        ForEach(Array(run.plan.localeCodes.enumerated()), id: \.element) { index, code in
                            if index > 0 { Divider() }
                            AutopilotLocaleRow(run: run, code: code, isWorking: studio.assistantIsWorking)
                        }
                    }
                    AutopilotExtrasRows(run: run)
                }
                .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
                AutopilotLogView(entries: Array(run.log.suffix(8)))
            }
            .padding(Spacing.xLarge)
        }
        .accessibilityIdentifier("autopilot.localize")
    }

    private var client: String { run.client ?? String(localized: "The assistant") }

    private var isExtrasOnly: Bool { !run.plan.makesScreenshots }

    /// Screenshots ready; without them, the artwork's languages rendered,
    /// else the App Previews made.
    private var progress: (done: Int, total: Int) {
        guard isExtrasOnly else { return (run.checkedScreenshots, run.totalScreenshots) }
        let extras = run.extrasProgress
        if !run.plan.artworkKinds.isEmpty { return (extras?.artworkDone ?? 0, run.plan.localeCodes.count) }
        return (extras?.previewsDone ?? 0, run.plan.previewDisplays.count * run.plan.previewLocales.count)
    }

    private var countText: String {
        guard isExtrasOnly else { return String(localized: "\(progress.done) of \(progress.total) ready") }
        return run.plan.artworkKinds.isEmpty
            ? String(localized: "\(progress.done) of \(progress.total) App Previews")
            : String(localized: "\(progress.done) of \(progress.total) languages")
    }

    /// Each language's search headline (and header line): what the
    /// assistant still writes, or that they're all there.
    private var headlinesRow: some View {
        let needs = run.artworkTextNeeds ?? []
        let names = Array(Set(needs.map(\.locale))).sorted().map { StoreLocaleCatalog.locale(code: $0)?.name ?? $0 }
        return HStack(spacing: Spacing.medium) {
            Text("Headlines").frame(width: 170, alignment: .leading)
            Text(needs.isEmpty
                ? String(localized: "Every language has its search headline, and it fits")
                : String(localized: "\(client) writes \(AutopilotArtworkTextWork(needs).summary): \(names.formatted(.list(type: .and)))"))
                .font(.callout)
                .foregroundStyle(needs.isEmpty ? Palette.label : Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if needs.isEmpty {
                    Image(systemName: "checkmark").foregroundStyle(Palette.positive)
                } else if studio.assistantIsWorking {
                    ProgressView().controlSize(.mini)
                }
            }
            .frame(width: 18)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.localize.headlines")
    }

    private var subtitle: String {
        let direction = run.chosenDirection?.name ?? String(localized: "the chosen direction")
        if isExtrasOnly {
            let what = run.plan.extrasTitle ?? String(localized: "the extras")
            let made = String(localized: "AppLocalizer makes \(what) with \(direction) and checks each; the live screenshots stay as they are.")
            guard !run.plan.artworkKinds.isEmpty else { return made }
            return made + " " + String(localized: "\(client) writes the search headline where one is missing and shortens the ones too long.")
        }
        return String(localized: """
        AppLocalizer lays out every screenshot in each language with \(direction) and checks each caption fits; \
        \(client) translates the missing ones and shortens the ones too long.
        """)
    }

    /// AppLocalizer checking a language, or the assistant on the captions
    /// while it works on the run; nil while nobody does (the status says why).
    private var happeningNow: String? {
        if let checking = run.plan.localeCodes.first(where: { run.localeStatus[$0] == .checking }) {
            let name = StoreLocaleCatalog.locale(code: checking)?.name ?? checking
            return String(localized: "Checking \(name) on this Mac…")
        }
        if let extras = run.extrasProgress, !extras.isFinished {
            return extras.isArtworkDone
                ? String(localized: "Assembling the App Preview on this Mac…")
                : String(localized: "Rendering the header and search artwork on this Mac…")
        }
        if run.overflows.isEmpty, let needs = run.artworkTextNeeds, !needs.isEmpty, studio.assistantIsWorking {
            return String(localized: "\(client) is writing the header’s and search image’s own texts: \(AutopilotArtworkTextWork(needs).summary).")
        }
        let work = AutopilotCaptionWork(run.overflows)
        guard !work.isEmpty, studio.assistantIsWorking else { return nil }
        return work.doing(by: client) + " " + String(localized: "Each language is checked again when they arrive.")
    }

    private var launchNote: String {
        isExtrasOnly
            ? String(localized: "It writes the headlines that are missing or too long and sends them here; AppLocalizer checks each language again.")
            : String(localized: "It writes the captions that are missing or too long and sends them here; AppLocalizer checks each language again.")
    }
}
