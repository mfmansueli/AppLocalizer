//
//  FontScriptRow.swift
//  AppLocalizer
//

import Foundation

/// One row of the inspector's "Fonts by script": whether the display font
/// draws the script, else its fallback and the fonts that could be.
struct FontScriptRow: Hashable, Sendable, Identifiable {
    var script: ScreenshotScript
    var displayFont: String
    /// The display font has a glyph for each of the script's letters.
    var isDrawnByDisplayFont: Bool
    /// The template's fallback for the script, if it names one.
    var fallback: String?
    /// Fonts the picker offers: the ones that can draw the script.
    var options: [String]
    /// Localized locales written in the script.
    var localeCount: Int

    var id: String { script.rawValue }

    /// Neither the display font nor a fallback draws it.
    var hasProblem: Bool { !isDrawnByDisplayFont && fallback == nil }

    /// The red pill: "1 locale fails", or "None set" when no locale uses
    /// the script yet.
    var problemText: String {
        switch localeCount {
        case 0: String(localized: "None set")
        case 1: String(localized: "1 locale fails")
        default: String(localized: "\(localeCount) locales fail")
        }
    }

    /// "Drawn by SF Pro Display", "Uses Hiragino Sans", "No font for this
    /// script".
    var status: String {
        if isDrawnByDisplayFont { return String(localized: "Drawn by \(displayFont)") }
        if let fallback { return String(localized: "Uses \(fallback)") }
        return String(localized: "No font for this script")
    }
}
