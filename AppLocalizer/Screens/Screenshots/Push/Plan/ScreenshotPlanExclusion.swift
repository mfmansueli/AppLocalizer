//
//  ScreenshotPlanExclusion.swift
//  AppLocalizer
//

import Foundation

/// A render that differs from what's live but can't go in this push: a
/// failed check (overflow, missing glyphs, wrong size), or a locale App
/// Store Connect has no localization for on the version yet. Review &
/// Push names them above the footer, with Show in Captions.
struct ScreenshotPlanExclusion: Identifiable, Hashable, Sendable {
    var appID: StoreApp.ID
    var cell: ScreenshotCellKey
    var localeName: String
    /// "Overflow", or nil when the locale isn't on the version.
    var failedCheck: String?

    var id: String { "\(appID)|\(cell)" }

    var isFailedCheck: Bool { failedCheck != nil }

    /// "German iPhone slot 3 (Overflow)".
    var title: String {
        let slot = String(localized: "\(localeName) \(cell.displayType.shortTitle) slot \(cell.slot + 1)")
        guard let failedCheck else { return slot }
        return "\(slot) (\(failedCheck))"
    }
}
