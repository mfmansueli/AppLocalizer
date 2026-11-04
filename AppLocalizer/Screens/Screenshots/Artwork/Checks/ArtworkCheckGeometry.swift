//
//  ArtworkCheckGeometry.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Where a header or search image's parts landed, for `ArtworkChecker`:
/// from AppLocalizer's own layout (`init(layout:template:)`) or from a
/// Claude Design page as rendered (`init(web:kind:)`). Geometry is in
/// artwork pixels.
struct ArtworkCheckGeometry: Hashable, Sendable {
    /// One text drawn on the image, with how well it reads on what's behind
    /// it (nil when that can't be known, e.g. gradient text).
    struct Text: Hashable, Sendable {
        /// "the headline", "the app’s name".
        var name: String
        var text: String
        var frame: CGRect
        var contrast: Double?
    }

    var size: CGSize
    var safeArea: CGRect
    /// The headline's text and boxes, then the app's name.
    var headline: [Text]
    var appName: Text?
    /// The icon and the name together, as one label.
    var labelFrame: CGRect?
    /// The phones or screens, as turned; the part inside the image.
    var interfaceFrames: [CGRect]
    var visibleFocalFrame: CGRect?
    /// The image's own colors, for whether the header shares the first
    /// screenshot's.
    var colors: [TemplateColor]
    /// The headline's typeface, as a template names it.
    var headlineFont: String?
    /// What moves in a loop that should stay still: text, the icon.
    var moving: [String] = []
    /// A Claude Design page's own words (`data-al="text"`), as shown.
    var texts: [Text] = []

    /// Every text drawn, for the content checks.
    var textLayers: [String] {
        [headline.map(\.text).joined(separator: " "), appName?.text ?? ""] + texts.map(\.text)
    }

    /// AppLocalizer's own layout: the line boxes, the label, the phones,
    /// the template's background.
    init(layout: ArtworkLayout, template: ScreenshotTemplate) {
        size = layout.size
        safeArea = layout.safeArea
        let headlineName = String(localized: "the headline")
        headline = layout.lines.filter { !$0.isOverflow }.map { line in
            Text(
                name: headlineName, text: line.text, frame: line.frame,
                contrast: ArtworkChecker.textRatio(line, background: layout.background, size: layout.size)
            )
        }
        // Overflowing lines count for where the text runs, not for contrast.
        headline += layout.lines.filter(\.isOverflow).map { Text(name: headlineName, text: $0.text, frame: $0.frame, contrast: nil) }
        appName = layout.appLabel.map { label in
            Text(
                name: String(localized: "the app’s name"), text: label.name.text, frame: label.name.frame,
                contrast: ArtworkChecker.textRatio(label.name, background: layout.background, size: layout.size)
            )
        }
        labelFrame = layout.appLabel.map { $0.iconFrame.union($0.name.frame) }
        interfaceFrames = layout.phones.map(\.bounds)
        visibleFocalFrame = layout.visibleFocalFrame
        colors = template.background.stops.compactMap(TemplateColor.init)
        headlineFont = layout.lines.first?.fontName
    }

    init(
        size: CGSize, safeArea: CGRect, headline: [Text], appName: Text?, labelFrame: CGRect?, interfaceFrames: [CGRect],
        visibleFocalFrame: CGRect?, colors: [TemplateColor], headlineFont: String?, moving: [String] = [], texts: [Text] = []
    ) {
        self.size = size
        self.safeArea = safeArea
        self.headline = headline
        self.appName = appName
        self.labelFrame = labelFrame
        self.interfaceFrames = interfaceFrames
        self.visibleFocalFrame = visibleFocalFrame
        self.colors = colors
        self.headlineFont = headlineFont
        self.moving = moving
        self.texts = texts
    }
}
