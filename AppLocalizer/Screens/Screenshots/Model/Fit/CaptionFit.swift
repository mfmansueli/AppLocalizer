//
//  CaptionFit.swift
//  AppLocalizer
//

import Foundation

/// How one caption block (headline or subhead) fits its reserved box:
/// the lines it breaks into, the size it's set at, and the fill the fit
/// meter shows. Sizes are in u.
struct CaptionFit: Hashable, Sendable {
    var text: String
    var lines: [String]
    /// The size it's set at: the full size, a shrunk size, or the
    /// smallest size when it overflows.
    var size: Double
    /// The block's full size, after the hero ×1.06.
    var fullSize: Double
    var minimumSize: Double
    var maxLines: Int
    var fits: Bool
    /// A word is wider than the box and hyphenation is off.
    var hasWideWord: Bool
    /// Text width at full size ÷ (maxLines × box width).
    var fill: Double

    var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var isShrunk: Bool { fits && size < fullSize - 0.01 }

    /// Lines past `maxLines`, drawn dimmed.
    var extraLines: Int { max(0, lines.count - maxLines) }

    var tone: FitTone {
        if isEmpty { return .empty }
        if !fits { return .overflows }
        return isShrunk ? .shrinks : .fits
    }

    /// "Fits at 112 u", "Shrinks to 92 u", "1 line too many at 80 u".
    var label: String {
        let sizeText = Int(size.rounded())
        switch tone {
        case .empty:
            return String(localized: "No caption")
        case .fits:
            return String(localized: "Fits at \(sizeText) u")
        case .shrinks:
            return String(localized: "Shrinks to \(sizeText) u")
        case .overflows:
            if extraLines == 1 { return String(localized: "1 line too many at \(sizeText) u") }
            if extraLines > 1 { return String(localized: "\(extraLines) lines too many at \(sizeText) u") }
            return String(localized: "A word is wider than the box at \(sizeText) u")
        }
    }

    /// "Caption fits at 119 u, 1 line", for the passed fit check.
    var summary: String {
        let sizeText = Int(size.rounded())
        let lineText = lines.count == 1 ? String(localized: "1 line") : String(localized: "\(lines.count) lines")
        return isShrunk
            ? String(localized: "Caption shrinks to \(sizeText) u, \(lineText)")
            : String(localized: "Caption fits at \(sizeText) u, \(lineText)")
    }
}
