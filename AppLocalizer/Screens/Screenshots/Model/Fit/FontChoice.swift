//
//  FontChoice.swift
//  AppLocalizer
//

import Foundation

/// The font a caption block is set in for one locale: the block's font
/// when it has every character, else the template's fallback for the
/// locale's script. Characters neither has fail the glyph check: they're
/// never drawn as empty boxes without saying so.
struct FontChoice: Hashable, Sendable {
    /// The font the block is set in.
    var fontName: String
    /// The block's own font, as the template names it.
    var requestedFont: String
    var script: ScreenshotScript
    /// The font came from `fonts.fallback`.
    var isFallback: Bool
    /// Characters `fontName` has no glyph for, in order.
    var missingCharacters: String

    var hasAllGlyphs: Bool { missingCharacters.isEmpty }

    /// Picks the font for `text`.
    static func choose(
        font requested: String,
        for text: String,
        script: ScreenshotScript,
        fonts: TemplateFonts,
        catalog: ScreenshotFontCatalog
    ) -> FontChoice {
        let own = catalog.missingCharacters(in: text, fontNamed: requested)
        guard !own.isEmpty, !text.isEmpty else {
            return FontChoice(fontName: requested, requestedFont: requested, script: script, isFallback: false, missingCharacters: "")
        }
        guard let fallback = fonts.fallback(for: script) else {
            return FontChoice(fontName: requested, requestedFont: requested, script: script, isFallback: false, missingCharacters: String(own))
        }
        let missing = catalog.missingCharacters(in: text, fontNamed: fallback)
        return FontChoice(fontName: fallback, requestedFont: requested, script: script, isFallback: true, missingCharacters: String(missing))
    }

    /// "Missing glyphs: Northpier Display has no Thai letters and no
    /// fallback font is set", or nil when every character has a glyph.
    var problem: String? {
        guard !hasAllGlyphs else { return nil }
        if !isFallback, script != .latin {
            return String(localized: "Missing glyphs: \(requestedFont) has no \(script.title) letters and no fallback font is set")
        }
        let characters = missingCharacters.prefix(4).map(String.init).joined(separator: " ")
        return String(localized: "Missing glyphs: \(fontName) has no glyph for \(characters)")
    }
}
