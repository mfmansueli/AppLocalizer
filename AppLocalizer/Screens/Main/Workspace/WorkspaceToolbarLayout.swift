//
//  WorkspaceToolbarLayout.swift
//  AppLocalizer
//

import CoreGraphics

/// Whether the workspace toolbar's title must shrink to "Lume…" so Review &
/// Push keeps its place: what the detail column leaves after the section
/// picker, the assistant indicator, Refresh, Activity and Review & Push.
/// A toolbar never shrinks a title on its own, and an item keeps the size
/// it first had, so the title switches between two items instead of
/// resizing one.
struct WorkspaceToolbarLayout: Equatable {
    var detailWidth: CGFloat = 0
    var pickerWidth: CGFloat = 0
    /// Zero while the indicator is hidden.
    var indicatorWidth: CGFloat = 0

    /// "Lume…" over "dev.nor…", as the design draws it.
    static let compactTitleWidth: CGFloat = 64
    /// The narrowest full title worth keeping before switching to compact.
    static let fullTitleMinimum: CGFloat = 150
    static let maxTitleWidth: CGFloat = 240
    /// Refresh, Activity and Review & Push, and the toolbar's padding and
    /// spacing. Review & Push isn't measured: in the overflow menu it
    /// measures as the menu's button.
    static let fixedWidth: CGFloat = 335

    /// What the title can have, or nil before the column is measured.
    var spareWidth: CGFloat? {
        guard detailWidth > 0 else { return nil }
        return detailWidth - pickerWidth - indicatorWidth - Self.fixedWidth
    }

    var isTitleCompact: Bool {
        spareWidth.map { $0 < Self.fullTitleMinimum } ?? false
    }
}
