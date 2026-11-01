//
//  TemplateDecoration.swift
//  AppLocalizer
//

import Foundation

/// One entry of `deco`: a shape, a rating laurel or a badge drawn behind
/// the device (`z: back`) or in front of it. `x` and `w` (width) are
/// fractions of the canvas width, `y` and `h` (height) of its height; the
/// height defaults to square.
/// Mirrored in right-to-left locales, with laurels and badges keeping their
/// text readable. Their text is numbers and symbols only, so it never needs
/// translating. Usually set per slot.
struct TemplateDecoration: Codable, Hashable, Sendable {
    var type: Kind
    /// The shape, for `type: shape`.
    var shape: Shape?
    var x: Double
    var y: Double
    /// `w` in JSON.
    var width: Double
    /// `h` in JSON; square when left out.
    var height: Double?
    var color: String
    /// `z` in JSON.
    var layer: Layer
    /// Degrees, clockwise (`rot`); mirrored in right-to-left locales.
    var rotation: Double?
    /// Opacity, 0–1 (`op`).
    var opacity: Double?
    /// A laurel's or badge's text: "4.8", "4.8 ★".
    var value: String?
    /// Five stars under a laurel's value.
    var stars: Bool?
    /// The stars' color; the laurel's when left out.
    var star: String?
    /// The text's color; white on a badge, the laurel's own color on a
    /// laurel, when left out.
    var ink: String?

    enum CodingKeys: String, CodingKey {
        case type, shape, x, y
        case width = "w"
        case height = "h"
        case color
        case layer = "z"
        case rotation = "rot"
        case opacity = "op"
        case value, stars, star, ink
    }

    enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        case shape
        /// A value with laurel branches on both sides, and stars.
        case laurel
        /// A value on a starburst.
        case badge
    }

    enum Shape: String, Codable, Hashable, Sendable, CaseIterable {
        case sparkle
        case blob
        case swoosh
        case wave
        case arc
        case petal
        case circle
        case chevrons
    }

    enum Layer: String, Codable, Hashable, Sendable, CaseIterable {
        /// Behind the device.
        case back
        /// Over the device and the band, under the caption.
        case front
    }

    static func shape(
        _ shape: Shape, x: Double, y: Double, width: Double, height: Double? = nil, color: String, layer: Layer,
        rotation: Double? = nil, opacity: Double? = nil
    ) -> TemplateDecoration {
        TemplateDecoration(
            type: .shape, shape: shape, x: x, y: y, width: width, height: height, color: color, layer: layer, rotation: rotation, opacity: opacity
        )
    }

    /// A rating between laurel branches, with five stars under it.
    static func laurel(x: Double, y: Double, width: Double, color: String, value: String, star: String? = nil) -> TemplateDecoration {
        TemplateDecoration(type: .laurel, x: x, y: y, width: width, color: color, layer: .front, value: value, stars: true, star: star)
    }

    /// A rating on a starburst.
    static func badge(x: Double, y: Double, width: Double, color: String, ink: String, value: String, rotation: Double? = nil) -> TemplateDecoration {
        TemplateDecoration(type: .badge, x: x, y: y, width: width, color: color, layer: .front, rotation: rotation, value: value, ink: ink)
    }

    /// Laurels and badges show a rating, which must be true.
    var isRating: Bool { type == .laurel || type == .badge }

    /// The number a laurel or badge shows: 4.8 for "4.8 ★" or "4,8".
    var ratingValue: Double? {
        guard isRating, let value else { return nil }
        return Self.number(in: value)
    }

    /// The first number in a value, with a comma or a point.
    static func number(in value: String) -> Double? {
        let digits: ClosedRange<Character> = "0"..."9"
        let number = value.drop { !digits.contains($0) }.prefix { digits.contains($0) || $0 == "." || $0 == "," }
        return Double(number.replacingOccurrences(of: ",", with: "."))
    }

    /// "Rating laurel", "Badge", "Sparkle", "Ribbon"…
    var title: String {
        switch type {
        case .laurel: String(localized: "Rating laurel")
        case .badge: String(localized: "Badge")
        case .shape: shape?.title ?? String(localized: "Shape")
        }
    }
}

extension TemplateDecoration.Shape {
    var title: String {
        switch self {
        case .sparkle: String(localized: "Sparkle")
        case .blob: String(localized: "Blob")
        case .swoosh: String(localized: "Ribbon")
        case .wave: String(localized: "Wave")
        case .arc: String(localized: "Corner")
        case .petal: String(localized: "Petals")
        case .circle: String(localized: "Circle")
        case .chevrons: String(localized: "Chevrons")
        }
    }
}
