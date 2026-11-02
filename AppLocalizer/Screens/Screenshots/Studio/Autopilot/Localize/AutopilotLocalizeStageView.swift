//
//  AutopilotLocalizeStageView.swift
//  AppLocalizer
//

import SwiftUI

/// Localize and check: how many screenshots are ready, what's happening
/// now (AppLocalizer checking a language, or the assistant translating or
/// shortening captions), who's working on them and what it's doing (or why
/// nobody is, with Continue), each language as AppLocalizer renders and
/// checks it, and the log.
struct AutopilotLocalizeStageView: View {
    @Bindable var studio: ScreenshotStudioModel
    let run: AutopilotRun

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Localize and check").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text("\(run.checkedScreenshots) of \(run.totalScreenshots) ready")
                            .monospacedDigit()
                            .foregroundStyle(Palette.label2)
                            .accessibilityIdentifier("autopilot.localize.count")
                    }
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ProgressView(value: Double(run.checkedScreenshots), total: Double(max(run.totalScreenshots, 1)))
                    .accessibilityLabel(Text("\(run.checkedScreenshots) of \(run.totalScreenshots) screenshots ready"))
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
                    ForEach(Array(run.plan.localeCodes.enumerated()), id: \.element) { index, code in
                        if index > 0 { Divider() }
                        AutopilotLocaleRow(run: run, code: code, isWorking: studio.assistantIsWorking)
                    }
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

    private var subtitle: String {
        let direction = run.chosenDirection?.name ?? String(localized: "the chosen direction")
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
        let work = AutopilotCaptionWork(run.overflows)
        guard !work.isEmpty, studio.assistantIsWorking else { return nil }
        return work.doing(by: client) + " " + String(localized: "Each language is checked again when they arrive.")
    }

    private var launchNote: String {
        String(localized: "It writes the captions that are missing or too long and sends them here; AppLocalizer checks each language again.")
    }
}
