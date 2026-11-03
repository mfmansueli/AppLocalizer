//
//  ArtworkCheckInput.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// One rendered header or search image in one language, with what it was
/// made from, for `ArtworkChecker`.
struct ArtworkCheckInput {
    var kind: AutopilotArtworkKind
    var locale: StoreLocale
    /// Header, search, or both for the 16:9 image.
    var roles: [ArtworkTextRole]
    /// The flattened render, the pixels `ArtworkRenderer` writes; nil
    /// leaves out what's read from pixels (the text in it, alpha, edges).
    var image: CGImage?
    /// The PNG as uploaded, for its alpha channel.
    var pngData: Data?
    /// Its text layers, phones and safe area.
    var layout: ArtworkLayout
    /// The line as written: the search headline or the header's line.
    var line: String
    /// The artwork's template.
    var template: ScreenshotTemplate
    /// The direction's screenshot template and the first screenshot's
    /// layout, for whether the header shares their look.
    var screenshotTemplate: ScreenshotTemplate?
    var firstScreenshot: ScreenshotLayout?

    init(
        kind: AutopilotArtworkKind, locale: StoreLocale, roles: [ArtworkTextRole]? = nil, image: CGImage?, pngData: Data? = nil,
        layout: ArtworkLayout, line: String, template: ScreenshotTemplate,
        screenshotTemplate: ScreenshotTemplate? = nil, firstScreenshot: ScreenshotLayout? = nil
    ) {
        self.kind = kind
        self.locale = locale
        self.roles = roles ?? ArtworkTextRole.placementRoles(for: kind)
        self.image = image
        self.pngData = pngData
        self.layout = layout
        self.line = line
        self.template = template
        self.screenshotTemplate = screenshotTemplate
        self.firstScreenshot = firstScreenshot
    }

    /// "German header", "Japanese search image".
    var place: String {
        String(localized: "\(locale.name) \(ArtworkTextRole.placementTitle(of: roles))")
    }
}
