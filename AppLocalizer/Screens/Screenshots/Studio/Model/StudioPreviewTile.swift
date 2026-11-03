//
//  StudioPreviewTile.swift
//  AppLocalizer
//

import Foundation

/// The App Preview at the start of the preview's screenshots: its poster,
/// a chip ("New", or the language it's in when this one shows another's),
/// and the file the viewer plays.
struct StudioPreviewTile: Hashable {
    var template: ScreenshotTemplate
    var headline: String
    var capture: ScreenshotCapture?
    /// "0:24".
    var length: String
    var chip: String
    var file: ExtrasPreviewFile
}
