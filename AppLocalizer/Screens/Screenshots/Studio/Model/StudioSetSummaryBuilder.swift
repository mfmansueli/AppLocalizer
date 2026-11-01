//
//  StudioSetSummaryBuilder.swift
//  AppLocalizer
//

import Foundation

/// The Live set / New set card under the preview: how the set was made,
/// which languages have their own, iPad, iPhone Duo (required soon), Apple
/// Watch and Apple Vision Pro when the app runs there, and its checks.
struct StudioSetSummaryBuilder {
    var preview: StudioPreviewBuilder
    var templateVersion: Int?
    var captureCount: Int
    /// The devices the app runs on, as the Studio's device control lists them.
    var devices: [ScreenshotDisplayType] = ScreenshotDisplayType.rendered
    /// What "2 hours ago" is relative to.
    var now: Date = .now

    func summary() -> StudioSetSummary {
        preview.effectiveChoice == .new ? newSummary() : liveSummary()
    }

    // MARK: - Live

    private func liveSummary() -> StudioSetSummary {
        let live = preview.live
        let primary = preview.primaryLocale
        let locales = preview.storeTexts.locales.isEmpty ? [primary] : preview.storeTexts.locales
        let own = locales.filter { live.hasOwnSet(locale: $0.code) }
        let missing = locales.filter { !live.hasOwnSet(locale: $0.code) && $0.code != primary.code }
        var languages = String(localized: "\(own.count) of \(locales.count)")
        if !missing.isEmpty, !own.isEmpty {
            let names = missing.prefix(3).map(\.shortName) + (missing.count > 3 ? [String(localized: "\(missing.count - 3) more")] : [])
            languages += "; " + String(localized: "\(names.formatted(.list(type: .and))) show \(primary.shortName)")
        }
        let iPadSets = live.screenshotSets.filter { $0.displayType == .iPad && !$0.screenshots.isEmpty }
        let iPad = iPadSets.isEmpty
            ? String(localized: "None: the App Store shows the iPhone set")
            : String(localized: "Own screenshots in \(Set(iPadSets.map(\.locale)).count) of \(locales.count) languages")
        let duoSets = live.screenshotSets.filter { $0.displayType == .iPhoneDuo && !$0.screenshots.isEmpty }
        let duo = duoSets.isEmpty
            ? String(localized: "None yet: required from April 2027")
            : String(localized: "Own screenshots in \(Set(duoSets.map(\.locale)).count) of \(locales.count) languages")
        let phoneCount = live.set(locale: primary.code, displayType: .iPhone)?.screenshots.count ?? 0
        var lines: [StudioSetSummary.Line] = [
            .init(label: String(localized: "Made"), value: madeValue()),
            .init(label: String(localized: "Languages"), value: own.isEmpty ? String(localized: "None yet") : languages),
            .init(label: String(localized: "iPad"), value: iPad),
            .init(label: String(localized: "iPhone Duo"), value: duo),
        ]
        for display in ScreenshotDisplayType.ownScreens where devices.contains(display) {
            lines.append(.init(label: display.shortTitle, value: ownLiveValue(display, locales: locales)))
        }
        lines.append(.init(label: String(localized: "Screenshots"), value: String(localized: "\(phoneCount) on iPhone in \(primary.shortName)")))
        return StudioSetSummary(title: String(localized: "Live set"), pill: String(localized: "Live"), pillStyle: .neutral, lines: lines)
    }

    /// "None yet", "2 English captures" when only the primary language has
    /// them, else how many languages have their own.
    private func ownLiveValue(_ display: ScreenshotDisplayType, locales: [StoreLocale]) -> String {
        let sets = preview.live.screenshotSets.filter { $0.displayType == display && !$0.screenshots.isEmpty }
        guard !sets.isEmpty else { return String(localized: "None yet") }
        let primary = preview.primaryLocale
        if sets.count == 1, let only = sets.first, only.locale == primary.code {
            let count = only.screenshots.count
            return count == 1
                ? String(localized: "1 \(primary.shortName) capture")
                : String(localized: "\(count) \(primary.shortName) captures")
        }
        return String(localized: "Own screenshots in \(Set(sets.map(\.locale)).count) of \(locales.count) languages")
    }

    private func madeValue() -> String {
        let states = preview.matrix.cells.values.filter { $0.live != nil }.map(\.state)
        if states.isEmpty, preview.live.screenshotSets.isEmpty { return String(localized: "Nothing live yet") }
        if states.contains(.uploadedByHand) || states.isEmpty { return String(localized: "By hand, in App Store Connect") }
        return String(localized: "With AppLocalizer’s template")
    }

    // MARK: - New

    private func newSummary() -> StudioSetSummary {
        let matrix = preview.matrix
        let run = preview.run.flatMap { $0.stage == .ready ? $0 : nil }
        var design = [preview.newSetName ?? String(localized: "Template")]
        if let templateVersion { design.append(String(localized: "template v\(templateVersion)")) }
        if let direction = run?.chosenDirection { design.append(direction.sourceTitle) }
        let captures = if let run, let client = run.client {
            String(localized: "\(client) in Simulator · \(relative(run.finishedAt ?? run.createdAt))")
        } else if captureCount == 1 {
            String(localized: "1 capture")
        } else {
            String(localized: "\(captureCount) captures")
        }
        let displays = ScreenshotDisplayType.studio.filter { display in
            matrix.localizedCells.contains { $0.key.displayType == display && $0.state.isPending }
        }
        let languages = matrix.localizedLocales.count
        let screenshots = [
            "\(matrix.pendingCount)",
            displays.map(\.shortTitle).formatted(.list(type: .and)),
            languages == 1 ? String(localized: "1 language") : String(localized: "\(languages) languages"),
        ]
        return StudioSetSummary(
            title: String(localized: "New set"),
            pill: String(localized: "Not pushed"),
            pillStyle: .accent,
            lines: [
                .init(label: String(localized: "Design"), value: design.joined(separator: " · ")),
                .init(label: String(localized: "Captures"), value: captures),
                .init(label: String(localized: "Screenshots"), value: screenshots.filter { !$0.isEmpty }.joined(separator: " · ")),
                .init(label: String(localized: "Checks"), value: checksValue(shortened: run?.shortenings.count ?? 0)),
            ]
        )
    }

    /// "2 hours ago"; a date past `now` (another Mac's clock) reads "now".
    private func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: min(date, now), relativeTo: now)
    }

    private func checksValue(shortened: Int) -> String {
        let failed = preview.matrix.failedCells.count
        if failed == 1 { return String(localized: "1 fails its check") }
        if failed > 1 { return String(localized: "\(failed) fail their checks") }
        if shortened == 1 { return String(localized: "All fit after 1 caption was shortened") }
        if shortened > 1 { return String(localized: "All fit after \(shortened) captions were shortened") }
        return String(localized: "All fit")
    }
}
