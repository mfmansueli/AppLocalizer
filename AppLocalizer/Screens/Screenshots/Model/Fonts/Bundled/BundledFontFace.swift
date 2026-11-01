//
//  BundledFontFace.swift
//  AppLocalizer
//

import Foundation

/// One font file AppLocalizer ships, e.g. `PlayfairDisplay-BoldItalic.ttf`.
struct BundledFontFace: Hashable, Sendable {
    /// The file's name without `.ttf`, which is also its PostScript name.
    var postScriptName: String
    /// CSS-style weight, 100–900.
    var weight: Int
    var isItalic: Bool

    init(_ postScriptName: String, weight: Int, italic: Bool = false) {
        self.postScriptName = postScriptName
        self.weight = weight
        isItalic = italic
    }
}
