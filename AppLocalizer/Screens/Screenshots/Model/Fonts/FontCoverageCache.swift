//
//  FontCoverageCache.swift
//  AppLocalizer
//

import Foundation

/// Remembers which fonts draw which scripts, so the template inspector
/// doesn't create a font per script on every edit. Answers for one
/// catalog; another catalog (an uploaded font) starts over.
struct FontCoverageCache {
    private var catalog: ScreenshotFontCatalog?
    private var coverage: [String: Bool] = [:]
    private var drawing: [ScreenshotScript: [String]] = [:]

    /// Whether `font` has every letter of the script's sample text.
    mutating func covers(_ font: String, _ script: ScreenshotScript, in catalog: ScreenshotFontCatalog) -> Bool {
        reset(for: catalog)
        let key = "\(font)|\(script.rawValue)"
        if let known = coverage[key] { return known }
        let covers = catalog.covers(font, script.sampleText)
        coverage[key] = covers
        return covers
    }

    /// The known and uploaded fonts that draw the script.
    mutating func fonts(drawing script: ScreenshotScript, in catalog: ScreenshotFontCatalog) -> [String] {
        reset(for: catalog)
        if let known = drawing[script] { return known }
        let fonts = catalog.fonts(drawing: script)
        drawing[script] = fonts
        return fonts
    }

    private mutating func reset(for catalog: ScreenshotFontCatalog) {
        guard self.catalog != catalog else { return }
        self.catalog = catalog
        coverage = [:]
        drawing = [:]
    }
}
