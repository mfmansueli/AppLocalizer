//
//  ScreenshotsServices+Autopilot.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ScreenshotsServices {
    var autopilot: AutopilotCenter? { nil }

    var appSupport: AppSupportCenter? { nil }

    var initialTab: ScreenshotsTab { .preview }

    func storeCapture(_ data: Data, for _: StoreApp) async throws -> CaptureFile {
        try Self.captureFile(for: data)
    }

    /// The checksum and size of a PNG, or why it isn't one.
    static func captureFile(for data: Data) throws -> CaptureFile {
        guard let image = ScreenshotPNG.image(data) else {
            throw AutopilotError(String(localized: "That isn’t a PNG. Send the screenshot file’s bytes."))
        }
        return CaptureFile(id: ScreenshotPNG.checksum(data), pixelSize: PixelSize(width: image.width, height: image.height))
    }
}
