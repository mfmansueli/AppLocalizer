//
//  CapturesViewModel+Viewer.swift
//  AppLocalizer
//

import Foundation

/// Opening a capture from the coverage and stepping through the others.
extension CapturesViewModel {
    /// Shows the cell's capture large; a missing one has nothing to show.
    func view(_ cell: CaptureCoverage.Cell, of row: CaptureCoverage.Row) {
        guard cell.capture != nil else { return }
        viewed = CaptureViewerTarget(localeCode: row.locale.code, slot: cell.slot)
    }

    /// ← →: the locale's screen before or after.
    func stepViewedScreen(by offset: Int) {
        guard let viewed, let coverage else { return }
        self.viewed = coverage.target(from: viewed, screens: offset)
    }

    /// ↑ ↓: the same screen in the locale above or below.
    func stepViewedLocale(by offset: Int) {
        guard let viewed, let coverage else { return }
        self.viewed = coverage.target(from: viewed, locales: offset)
    }

    /// The width the viewer loads a capture at: its own, up to 1,600 px.
    static func viewerPixelWidth(of capture: ScreenshotCapture) -> Int {
        min(max(capture.pixelSize.width, 1), 1600)
    }
}
