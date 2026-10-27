//
//  CaptureCoverage.swift
//  AppLocalizer
//

import Foundation

/// The Captures tab after an import (design `capt`): each locale's raw
/// captures on one display type, labelled Localized, English UI (the
/// primary's capture stands in) or Wrong size, with where the locale's
/// captures came from. Pure.
struct CaptureCoverage: Hashable {
    var groups: [Group]
    /// "52 captures · fastlane · imported Oct 26 · 10 locales have their
    /// own iPhone interface".
    var summary: String
    /// "English (U.S.) capture used, interface not localized".
    var legend: String
    /// The slots' names, for the column titles.
    var slotNames: [String]

    struct Group: Hashable, Identifiable {
        var title: String
        var rows: [Row]
        var id: String { title }
    }

    struct Row: Hashable, Identifiable {
        var locale: StoreLocale
        /// "fastlane · own" or "English (U.S.)".
        var sourceText: String
        var cells: [Cell]
        var id: String { locale.code }
    }

    struct Cell: Hashable, Identifiable {
        var slot: Int
        var capture: ScreenshotCapture?
        var label: Label
        var id: Int { slot }
    }

    enum Label: Hashable {
        case localized
        /// The primary's capture stands in: "English UI".
        case primaryInterface(language: String)
        case wrongSize
        case missing

        var title: String {
            switch self {
            case .localized: String(localized: "Localized")
            case let .primaryInterface(language): String(localized: "\(language) UI")
            case .wrongSize: String(localized: "Wrong size")
            case .missing: String(localized: "Missing")
            }
        }
    }

    // MARK: - Building

    struct Inputs {
        var document: ScreenshotsDocument
        var displayType: ScreenshotDisplayType
        var primary: StoreLocale
        /// Every App Store locale, in App Store Connect's order.
        var locales: [StoreLocale]
    }

    static func make(_ inputs: Inputs) -> CaptureCoverage {
        let document = inputs.document
        let primary = inputs.primary
        let byName = { (lhs: StoreLocale, rhs: StoreLocale) in lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending }
        let scoped = inputs.locales.filter { $0 != primary && document.scope.contains($0.code) }.sorted(by: byName)
        let captured = Set(document.captures.localesWithOwnInterface(displayType: inputs.displayType))
        let others = inputs.locales.filter { $0 != primary && !document.scope.contains($0.code) && captured.contains($0.code) }.sorted(by: byName)
        var groups = [Group(title: String(localized: "Localized sets"), rows: ([primary] + scoped).map { row(for: $0, inputs: inputs) })]
        if !others.isEmpty {
            groups.append(Group(title: String(localized: "Captured, not in the scope"), rows: others.map { row(for: $0, inputs: inputs) }))
        }
        return CaptureCoverage(
            groups: groups, summary: summary(inputs, capturedCount: captured.count),
            legend: String(localized: "\(primary.name) capture used, interface not localized"),
            slotNames: (0..<document.slotCount).map(document.slotName)
        )
    }

    private static func row(for locale: StoreLocale, inputs: Inputs) -> Row {
        let index = inputs.document.captures
        let display = inputs.displayType
        let own = index.captures.filter { $0.locale == locale.code && $0.displayType == display }
        let source = mostCommon(own.map(\.source))
        let sourceText = source.map { String(localized: "\($0.shortTitle) · own") } ?? inputs.primary.name
        let language = Locale.current.localizedString(forLanguageCode: inputs.primary.languageCode) ?? inputs.primary.name
        let cells = (0..<inputs.document.slotCount).map { slot -> Cell in
            guard let resolved = index.capture(locale: locale.code, displayType: display, slot: slot, primary: inputs.primary.code) else {
                return Cell(slot: slot, capture: nil, label: .missing)
            }
            if !fits(resolved.capture, display: display) { return Cell(slot: slot, capture: resolved.capture, label: .wrongSize) }
            let label: Label = resolved.isInterfaceLocalized ? .localized : .primaryInterface(language: language)
            return Cell(slot: slot, capture: resolved.capture, label: label)
        }
        return Row(locale: locale, sourceText: sourceText, cells: cells)
    }

    /// The other device class's capture, or one too small for the set.
    static func fits(_ capture: ScreenshotCapture, display: ScreenshotDisplayType) -> Bool {
        let isTabletCapture = capture.pixelSize.aspectRatio < CaptureSizeRules.tabletAspectLimit
        return isTabletCapture == display.isTablet && CaptureSizeRules.fits(capture.pixelSize, in: display)
    }

    private static func summary(_ inputs: Inputs, capturedCount: Int) -> String {
        let captures = inputs.document.captures.captures
        var parts = [captures.count == 1 ? String(localized: "1 capture") : String(localized: "\(captures.count) captures")]
        if let source = mostCommon(captures.map(\.source)) { parts.append(source.shortTitle) }
        if let date = captures.compactMap(\.importedAt).max() {
            parts.append(String(localized: "imported \(date.formatted(.dateTime.month(.abbreviated).day()))"))
        }
        let display = inputs.displayType.shortTitle
        parts.append(capturedCount == 1
            ? String(localized: "1 locale has its own \(display) interface")
            : String(localized: "\(capturedCount) locales have their own \(display) interface"))
        return parts.joined(separator: " · ")
    }

    private static func mostCommon(_ sources: [CaptureSource]) -> CaptureSource? {
        let counts = Dictionary(grouping: sources, by: \.self).mapValues(\.count)
        return CaptureSource.allCases.filter { counts[$0] != nil }.max { counts[$0, default: 0] < counts[$1, default: 0] }
    }
}
