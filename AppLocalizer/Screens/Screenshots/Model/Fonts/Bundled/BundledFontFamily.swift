//
//  BundledFontFamily.swift
//  AppLocalizer
//

import Foundation

/// A family AppLocalizer ships so the gallery's templates draw the same on
/// every Mac: the faces it has, each under the SIL Open Font License (the
/// license texts ship next to the fonts).
struct BundledFontFamily: Hashable, Sendable, Identifiable {
    /// The name templates use, e.g. "Playfair Display".
    var name: String
    var faces: [BundledFontFace]

    var id: String { name }

    /// The face closest to `weight` (the heavier one on a tie), italic when
    /// one is asked for and the family has one; nil only for a family
    /// without faces.
    func face(weight: Int, italic: Bool) -> BundledFontFace? {
        let italics = faces.filter(\.isItalic)
        let pool = italic && !italics.isEmpty ? italics : faces.filter { !$0.isItalic }
        return pool.min { first, second in
            let firstDistance = abs(first.weight - weight)
            let secondDistance = abs(second.weight - weight)
            return firstDistance == secondDistance ? first.weight > second.weight : firstDistance < secondDistance
        }
    }
}
