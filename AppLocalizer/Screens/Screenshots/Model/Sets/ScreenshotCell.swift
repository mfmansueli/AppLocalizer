//
//  ScreenshotCell.swift
//  AppLocalizer
//

import Foundation

/// One locale × display type × slot of the Sets matrix.
struct ScreenshotCell: Hashable, Sendable, Identifiable {
    var key: ScreenshotCellKey
    var state: ScreenshotCellState
    var image: CellImageSource
    var caption: ScreenshotCaption?
    var capture: ResolvedCapture?
    var checks: [RenderCheck]
    /// The capture shows the primary locale's interface: the "UI" chip.
    var showsPrimaryInterface: Bool
    /// An assistant's caption proposal waits for this cell: its monogram.
    var proposal: ChangeSource?
    /// What's live in this position now.
    var live: LiveScreenshot?

    var id: ScreenshotCellKey { key }

    var layout: ScreenshotLayout? { image.renderJob?.layout }

    var firstFailure: RenderCheck? { ScreenshotChecker.firstFailure(in: checks) }
}
