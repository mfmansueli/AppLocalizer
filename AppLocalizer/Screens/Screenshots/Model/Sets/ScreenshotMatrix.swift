//
//  ScreenshotMatrix.swift
//  AppLocalizer
//

import Foundation

/// The Sets matrix for every rendered display type: one cell per locale ×
/// display type × slot, with the locales grouped the way the rows are.
struct ScreenshotMatrix: Hashable, Sendable {
    var slotCount: Int
    var cells: [ScreenshotCellKey: ScreenshotCell]
    /// In the scope and rendered, primary first.
    var localizedLocales: [String]
    /// Restored and pinned.
    var restoredLocales: [String]
    /// Out of the scope: the App Store shows the primary locale's set.
    var fallbackLocales: [String]
    var hasTemplate: Bool
    var hasCaptures: Bool
    /// Apple Watch's and Apple Vision Pro's screens, when the set has them.
    var ownSlotCounts: [ScreenshotDisplayType: Int] = [:]

    static let empty = ScreenshotMatrix(
        slotCount: 0, cells: [:], localizedLocales: [], restoredLocales: [], fallbackLocales: [], hasTemplate: false, hasCaptures: false
    )

    func cell(locale: String, displayType: ScreenshotDisplayType, slot: Int) -> ScreenshotCell? {
        cells[ScreenshotCellKey(locale: locale, displayType: displayType, slot: slot)]
    }

    func row(locale: String, displayType: ScreenshotDisplayType) -> [ScreenshotCell] {
        (0..<slotCount(on: displayType)).compactMap { cell(locale: locale, displayType: displayType, slot: $0) }
    }

    /// The set's slots on iPhone and iPad; Apple Watch's and Apple Vision
    /// Pro's own screens, and iPhone Duo's when it has some.
    func slotCount(on display: ScreenshotDisplayType) -> Int {
        ownSlotCounts[display] ?? (display.hasOwnScreens ? 0 : slotCount)
    }

    /// iPhone and iPad, then the devices with screens of their own.
    var displays: [ScreenshotDisplayType] {
        ScreenshotDisplayType.rendered + ScreenshotDisplayType.ownScreens.filter { (ownSlotCounts[$0] ?? 0) > 0 }
    }

    /// The localized cells in push order: iPhone then iPad, locales in
    /// scope order, slots in order.
    var localizedCells: [ScreenshotCell] {
        displays.flatMap { display in
            localizedLocales.flatMap { row(locale: $0, displayType: display) }
        }
    }

    /// Renders waiting for Review & Push, on every display type.
    var pendingCount: Int {
        localizedCells.count { $0.state.isPending }
    }

    /// Renders that fail a check, in push order.
    var failedCells: [ScreenshotCell] {
        localizedCells.filter(\.state.isFailed)
    }

    /// Captions in the scope that overflow on `displayType`: the red count
    /// on Captions.
    func overflowingCaptionCount(on displayType: ScreenshotDisplayType) -> Int {
        localizedLocales.reduce(0) { total, locale in
            total + row(locale: locale, displayType: displayType).count { cell in
                cell.checks.contains { $0.kind == .fit && $0.status == .failed }
            }
        }
    }

    /// The localized cells' render jobs, deduplicated, in push order, for
    /// the render queue; the primary locale's come first so fallback rows
    /// fill in early.
    var renderJobs: [RenderJob] {
        var seen = Set<RenderKey>()
        return localizedCells.compactMap(\.image.renderJob).filter { seen.insert($0.key).inserted }
    }
}
