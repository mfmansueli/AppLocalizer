//
//  ScreenshotFontCatalog.swift
//  AppLocalizer
//

import AppKit
import CoreText

/// Turns the font names a template uses ("SF Pro Display", "Hiragino
/// Sans") into Core Text fonts, and answers whether a font can draw a text.
/// The SF families and New York are the system's own fonts, reached through
/// the system font rather than by name, so they work on every Mac; SF
/// Arabic and SF Hebrew are the system font's cascade for those scripts.
/// Any other name must be an installed family.
///
/// Coverage is read from the font's cmap with `CTFontGetGlyphsForCharacters`,
/// per character: Core Text and SwiftUI would silently fall back to another
/// font, which is exactly what the glyph check has to catch.
struct ScreenshotFontCatalog: Hashable, Sendable {
    /// Template names that stand for an installed family, e.g. an uploaded
    /// brand font registered under another name.
    var aliases: [String: String] = [:]
    /// Families uploaded in the template inspector, registered for this
    /// process; the font pickers mark them "· uploaded".
    var uploaded: [String] = []

    static let standard = ScreenshotFontCatalog()

    /// The fonts the template inspector offers, and the ones a refusal
    /// suggests for a script.
    static let knownFonts = [
        "SF Pro Display", "SF Pro Text", "New York", "SF Arabic", "Geeza Pro", "SF Hebrew", "Hiragino Sans",
        "PingFang SC", "PingFang TC", "Apple SD Gothic Neo", "Thonburi", "Kohinoor Devanagari",
    ]

    private static let systemFamilies: Set = ["SF Pro", "SF Pro Display", "SF Pro Text"]

    /// The font for `name` at `weight` (100–900) and `size` pixels, or nil
    /// when it isn't available on this Mac.
    func font(named name: String, weight: Int = 400, size: CGFloat) -> CTFont? {
        let family = aliases[name] ?? name
        let nsWeight = Self.weight(weight)
        if Self.systemFamilies.contains(family) {
            return NSFont.systemFont(ofSize: size, weight: nsWeight) as CTFont
        }
        switch family {
        case "New York":
            let serif = NSFont.systemFont(ofSize: size, weight: nsWeight).fontDescriptor.withDesign(.serif)
            return serif.flatMap { NSFont(descriptor: $0, size: size) }.map { $0 as CTFont }
        case "SF Arabic":
            return cascadeFont(for: "ع", weight: nsWeight, size: size, family: "Arabic")
        case "SF Hebrew":
            return cascadeFont(for: "א", weight: nsWeight, size: size, family: "Hebrew")
        default:
            return installedFont(family: family, weight: nsWeight, size: size)
        }
    }

    /// Whether `name` resolves to a font on this Mac.
    func isAvailable(_ name: String) -> Bool {
        font(named: name, size: 12) != nil
    }

    /// Whether `name` has a glyph for every character of `text` that needs
    /// one. Unavailable fonts cover nothing.
    func covers(_ name: String, _ text: String) -> Bool {
        guard let font = font(named: name, size: 12) else { return false }
        return Self.missingCharacters(in: text, font: font).isEmpty
    }

    /// The characters of `text` the font named `name` can't draw; all of
    /// them when the font isn't available.
    func missingCharacters(in text: String, fontNamed name: String) -> [Character] {
        guard let font = font(named: name, size: 12) else {
            var all: [Character] = []
            for character in text where !character.isWhitespace && !all.contains(character) {
                all.append(character)
            }
            return all
        }
        return Self.missingCharacters(in: text, font: font)
    }

    /// The known and uploaded fonts that can draw `script`.
    func fonts(drawing script: ScreenshotScript) -> [String] {
        (Self.knownFonts + uploaded.filter { !Self.knownFonts.contains($0) }).filter { covers($0, script.sampleText) }
    }

    /// The display fonts the headline picker offers: the system's, then
    /// uploaded ones.
    var displayFonts: [String] {
        Self.displayFamilies + uploaded.filter { !Self.displayFamilies.contains($0) }
    }

    func isUploaded(_ name: String) -> Bool {
        uploaded.contains(name)
    }

    private static let displayFamilies = ["SF Pro Display", "SF Pro Text", "New York"]

    /// The characters of `text` `font` has no glyph for, in order, without
    /// repeats. Spaces, joiners, direction marks and variation selectors
    /// don't need glyphs.
    static func missingCharacters(in text: String, font: CTFont) -> [Character] {
        var missing: [Character] = []
        for character in text where !missing.contains(character) {
            for scalar in character.unicodeScalars where needsGlyph(scalar) {
                let units = Array(String(scalar).utf16)
                var glyphs = [CGGlyph](repeating: 0, count: units.count)
                if !CTFontGetGlyphsForCharacters(font, units, &glyphs, units.count) {
                    missing.append(character)
                    break
                }
            }
        }
        return missing
    }

    private static func needsGlyph(_ scalar: Unicode.Scalar) -> Bool {
        let properties = scalar.properties
        if properties.isWhitespace || properties.isVariationSelector || properties.isDefaultIgnorableCodePoint { return false }
        return properties.generalCategory != .format && properties.generalCategory != .control
    }

    /// CSS-style weights to AppKit's: 400 regular, 700 bold.
    static func weight(_ value: Int) -> NSFont.Weight {
        switch value {
        case ..<150: .ultraLight
        case ..<250: .thin
        case ..<350: .light
        case ..<450: .regular
        case ..<550: .medium
        case ..<650: .semibold
        case ..<750: .bold
        case ..<850: .heavy
        default: .black
        }
    }

    private func cascadeFont(for sample: String, weight: NSFont.Weight, size: CGFloat, family: String) -> CTFont? {
        let system = NSFont.systemFont(ofSize: size, weight: weight) as CTFont
        let font = CTFontCreateForString(system, sample as CFString, CFRange(location: 0, length: (sample as NSString).length))
        let resolved = CTFontCopyFamilyName(font) as String
        return resolved.localizedCaseInsensitiveContains(family) ? font : nil
    }

    private func installedFont(family: String, weight: NSFont.Weight, size: CGFloat) -> CTFont? {
        let attributes: [CFString: Any] = [
            kCTFontFamilyNameAttribute: family,
            kCTFontTraitsAttribute: [kCTFontWeightTrait: weight.rawValue],
        ]
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
        let font = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        return (CTFontCopyFamilyName(font) as String) == family ? font : nil
    }
}
