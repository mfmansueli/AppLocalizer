//
//  CaptureCoverage+Viewer.swift
//  AppLocalizer
//

import Foundation

/// The Captures tab's viewer: a capture clicked in the table, shown large.
/// ← → step through the locale's screens, ↑ ↓ through the locales on the
/// same screen, both in the table's order, wrapping around and skipping
/// missing captures. Pure.
extension CaptureCoverage {
    /// Every row, in the table's order.
    var allRows: [Row] { groups.flatMap(\.rows) }

    func row(for target: CaptureViewerTarget) -> Row? {
        allRows.first { $0.locale.code == target.localeCode }
    }

    /// The target's cell, when it has a capture to show.
    func cell(for target: CaptureViewerTarget) -> Cell? {
        row(for: target)?.cells.first { $0.slot == target.slot && $0.capture != nil }
    }

    /// The same locale's next screen with a capture (`offset` −1 for the one before).
    func target(from target: CaptureViewerTarget, screens offset: Int) -> CaptureViewerTarget {
        guard let row = row(for: target) else { return target }
        let slots = row.cells.filter { $0.capture != nil }.map(\.slot)
        guard let slot = Self.step(slots, from: target.slot, by: offset) else { return target }
        return CaptureViewerTarget(localeCode: target.localeCode, slot: slot)
    }

    /// The same screen in the next locale with a capture there (`offset` −1 for the one above).
    func target(from target: CaptureViewerTarget, locales offset: Int) -> CaptureViewerTarget {
        let codes = localeCodes(showing: target.slot)
        guard let code = Self.step(codes, from: target.localeCode, by: offset) else { return target }
        return CaptureViewerTarget(localeCode: code, slot: target.slot)
    }

    /// "Screen 2 of 5": among the locale's screens with a capture.
    func screenPosition(of target: CaptureViewerTarget) -> String {
        let slots = row(for: target)?.cells.filter { $0.capture != nil }.map(\.slot) ?? []
        let index = (slots.firstIndex(of: target.slot) ?? 0) + 1
        return String(localized: "Screen \(index) of \(slots.count)")
    }

    /// "Locale 5 of 12": among the locales with a capture on that screen.
    func localePosition(of target: CaptureViewerTarget) -> String {
        let codes = localeCodes(showing: target.slot)
        let index = (codes.firstIndex(of: target.localeCode) ?? 0) + 1
        return String(localized: "Locale \(index) of \(codes.count)")
    }

    /// "German · 2 Week".
    func viewerTitle(of target: CaptureViewerTarget) -> String {
        let locale = row(for: target)?.locale.name ?? target.localeCode
        let name = slotNames.indices.contains(target.slot) ? slotNames[target.slot] : ""
        return String(localized: "\(locale) · \(target.slot + 1) \(name)").trimmingCharacters(in: .whitespaces)
    }

    /// "iPhone 6.9″ · 1320 × 2868 px · fastlane · de-DE/iPhone 17 Pro Max-02_Week.png".
    func viewerSubtitle(of target: CaptureViewerTarget, display: ScreenshotDisplayType) -> String {
        guard let capture = cell(for: target)?.capture else { return display.title }
        return [display.title, String(localized: "\(capture.pixelSize.title) px"), capture.source.title, capture.fileName].joined(separator: " · ")
    }

    /// What the table's label means for this capture.
    func viewerStatus(of target: CaptureViewerTarget, display: ScreenshotDisplayType) -> String? {
        guard let row = row(for: target), let cell = cell(for: target), let capture = cell.capture else { return nil }
        return switch cell.label {
        case .localized: String(localized: "Localized · the interface is \(row.locale.name)")
        case .primaryInterface: legend
        case .wrongSize: String(localized: "Wrong size · \(capture.pixelSize.title) doesn’t fit \(display.title) screenshots, so it isn’t used")
        case .missing: nil
        }
    }

    private func localeCodes(showing slot: Int) -> [String] {
        allRows.filter { row in row.cells.contains { $0.slot == slot && $0.capture != nil } }.map(\.locale.code)
    }

    /// The element `offset` away from `current`, wrapping around; the first
    /// (or last) when `current` isn't there.
    private static func step<Element: Equatable>(_ elements: [Element], from current: Element, by offset: Int) -> Element? {
        guard !elements.isEmpty else { return nil }
        guard let index = elements.firstIndex(of: current) else { return offset < 0 ? elements.last : elements.first }
        let count = elements.count
        return elements[((index + offset) % count + count) % count]
    }
}
