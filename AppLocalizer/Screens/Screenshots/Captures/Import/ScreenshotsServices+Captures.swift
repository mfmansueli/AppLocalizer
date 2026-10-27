//
//  ScreenshotsServices+Captures.swift
//  AppLocalizer
//

import Foundation

// What services that keep no files do on import: the records alone, each
// capture named by where it goes and the file it came from. DEBUG scenes
// draw their captures from those; `LiveScreenshotsServices` copies the
// files instead.
extension ScreenshotsServices {
    func importCaptures(_ items: [CaptureImportItem], for _: StoreApp) async throws -> [ScreenshotCapture] {
        let date = Date.now
        return items.map { item in
            let placement = item.placement
            return item.capture(id: "\(placement.locale)|\(placement.displayType.rawValue)|\(placement.slot)|\(item.candidate.path)", date: date)
        }
    }

    var attachmentReader: any XcresultAttachmentReader { XcrunAttachmentReader() }
}
