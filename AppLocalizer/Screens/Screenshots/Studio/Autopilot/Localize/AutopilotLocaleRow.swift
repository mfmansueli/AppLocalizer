//
//  AutopilotLocaleRow.swift
//  AppLocalizer
//

import SwiftUI

/// One language in Localize and check: waiting, rendering, fits (and how),
/// or captions out to the assistant, saying which are missing (to
/// translate) and which are too long, and whether it's working on them.
/// That's the usual work after a new direction, so it never looks like a
/// warning.
struct AutopilotLocaleRow: View {
    let run: AutopilotRun
    let code: String
    /// The assistant works on the run now (`ScreenshotStudioModel.assistantIsWorking`).
    var isWorking = true

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Text(title)
                .frame(width: 170, alignment: .leading)
            Text(detail)
                .font(.callout)
                .foregroundStyle(isDone ? Palette.label : Palette.label2)
                .frame(maxWidth: .infinity, alignment: .leading)
            mark.frame(width: 18)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("autopilot.localize.\(code)")
    }

    /// "Polish · new" for a language the App Store page doesn't have yet.
    private var title: String {
        let name = StoreLocaleCatalog.locale(code: code)?.name ?? code
        return isNew ? String(localized: "\(name) · new") : name
    }

    private var isNew: Bool { run.plan.addedLocaleCodes.contains(code) }

    private var status: AutopilotLocaleStatus { run.localeStatus[code] ?? .waiting }
    private var isDone: Bool { status.isDone }
    private var client: String { run.client ?? String(localized: "The assistant") }

    private var detail: String {
        let shortened = run.shortenings.filter { $0.locale == code }
        switch status {
        case .waiting:
            return String(localized: "Waiting to be checked")
        case .checking:
            let count = run.plan.screensPerLanguage
            return String(localized: "Rendering \(count) screenshots…")
        case let .shortening(count):
            var work = AutopilotCaptionWork(run.overflows, locale: code)
            // Before the check's overflows are in, all it knows is the count.
            if work.total != count { work = AutopilotCaptionWork(missing: 0, tooLong: count) }
            return work.rowText(by: client, isWorking: isWorking)
        case let .fits(note):
            if let first = shortened.first {
                return String(localized: "Slot \(first.slot + 1) was too long · \(first.client) shortened it to “\(first.after)”")
            }
            let page = isNew ? String(localized: "its App Store page is created when you push") : nil
            return [String(localized: "Fits"), note, page].compactMap(\.self).joined(separator: " · ")
        }
    }

    @ViewBuilder
    private var mark: some View {
        switch status {
        case .waiting: EmptyView()
        case .checking: ProgressView().controlSize(.mini)
        case .shortening:
            if isWorking {
                ProgressView().controlSize(.mini)
            } else {
                Image(systemName: "pencil.circle").foregroundStyle(Palette.label2).accessibilityHidden(true)
            }
        case .fits: Image(systemName: "checkmark").foregroundStyle(Palette.positive)
        }
    }
}
