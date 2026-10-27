//
//  CaptureImportItem.swift
//  AppLocalizer
//

import Foundation

/// A file to import and where it goes. `ScreenshotsServices.importCaptures`
/// copies it next to the document and returns its `ScreenshotCapture`.
struct CaptureImportItem: Hashable, Sendable {
    var candidate: CaptureCandidate
    var placement: CaptureMatchRow.Placement

    /// The capture it becomes, kept under `id`.
    func capture(id: String, pixelSize: PixelSize? = nil, date: Date) -> ScreenshotCapture {
        let size = pixelSize ?? candidate.pixelSize ?? placement.displayType.portraitPixelSize
        return ScreenshotCapture(
            id: id, locale: placement.locale, displayType: placement.displayType, slot: placement.slot,
            source: candidate.source, fileName: candidate.path, pixelSize: size, importedAt: date
        )
    }
}
