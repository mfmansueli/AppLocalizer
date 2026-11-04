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
    /// Where its text, phones and safe area landed.
    var geometry: ArtworkCheckGeometry
    /// The line as written: the search headline or the header's line.
    var line: String
    /// The direction's screenshot template and the first screenshot's
    /// layout, for whether the header shares their look.
    var screenshotTemplate: ScreenshotTemplate?
    var firstScreenshot: ScreenshotLayout?
    /// A Claude Design page as rendered, for what's missing from it.
    var page: ArtworkWebMeasure?
    /// The page's phrases are translated later, at Localize: a direction
    /// checked in the primary language before then isn't missing any.
    var phrasesTranslateLater = false

    /// AppLocalizer's own layout, in `template`'s look.
    init(
        kind: AutopilotArtworkKind, locale: StoreLocale, roles: [ArtworkTextRole]? = nil, image: CGImage?, pngData: Data? = nil,
        layout: ArtworkLayout, line: String, template: ScreenshotTemplate,
        screenshotTemplate: ScreenshotTemplate? = nil, firstScreenshot: ScreenshotLayout? = nil
    ) {
        self.init(
            kind: kind, locale: locale, roles: roles, image: image, pngData: pngData, geometry: ArtworkCheckGeometry(layout: layout, template: template),
            line: line, screenshotTemplate: screenshotTemplate, firstScreenshot: firstScreenshot
        )
    }

    /// Any image, from where its parts landed: a Claude Design page's is
    /// read from the page (`ArtworkCheckGeometry(web:kind:)`).
    init(
        kind: AutopilotArtworkKind, locale: StoreLocale, roles: [ArtworkTextRole]? = nil, image: CGImage?, pngData: Data? = nil,
        geometry: ArtworkCheckGeometry, line: String, screenshotTemplate: ScreenshotTemplate? = nil, firstScreenshot: ScreenshotLayout? = nil,
        page: ArtworkWebMeasure? = nil, phrasesTranslateLater: Bool = false
    ) {
        self.kind = kind
        self.locale = locale
        self.roles = roles ?? ArtworkTextRole.placementRoles(for: kind)
        self.image = image
        self.pngData = pngData
        self.geometry = geometry
        self.line = line
        self.screenshotTemplate = screenshotTemplate
        self.firstScreenshot = firstScreenshot
        self.page = page
        self.phrasesTranslateLater = phrasesTranslateLater
    }

    /// "German header", "Japanese search image".
    var place: String {
        String(localized: "\(locale.name) \(ArtworkTextRole.placementTitle(of: roles))")
    }
}
