//
//  TemplateDecoration.swift
//  AppLocalizer
//

import Foundation

/// One entry of `deco`: a shape, a rating laurel, a badge or a prop (`art`)
/// drawn behind the device (`z: back`) or in front of it. `x` and `w`
/// (width) are fractions of the canvas width, `y` and `h` (height) of its
/// height; the height defaults to square.
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
    /// A prop's color only tints the marks drawn in one color; white when
    /// left out.
    var color: String
    /// `z` in JSON.
    var layer: Layer
    /// Degrees, clockwise (`rot`); mirrored in right-to-left locales.
    var rotation: Double?
    /// Opacity, 0–1 (`op`).
    var opacity: Double?
    /// A laurel's or badge's text: "4.8", "4.8 ★". A laurel showing the
    /// App Store's rating draws that instead, and keeps this only where
    /// the rating can't be read.
    var value: String?
    /// Where a laurel's number comes from (`src`): the App Store's rating
    /// in each language's country (the default), or `value` as typed,
    /// checked against that rating before push. Badges are always typed.
    var source: RatingSource?
    /// Five stars under a laurel's value.
    var stars: Bool?
    /// The stars' color; the laurel's when left out.
    var star: String?
    /// The text's color; white on a badge, the laurel's own color on a
    /// laurel, when left out.
    var ink: String?
    /// The prop, for `type: art`.
    var art: TemplateArt?
    /// Places it by the caption instead of the canvas: `cap` puts `y`
    /// under the caption box (an offset from its bottom), `l1end` follows
    /// the end of the headline's first line in every language.
    var anchor: Anchor?
    /// What it does when a language's headline runs into it: move below
    /// the caption, step aside, or hide. Left out, it may overlap.
    var avoid: Avoidance?
    /// The slot (0-based) the same figure continues on, placed one canvas
    /// width apart so it lines up across the seam when people swipe.
    var span: Int?
    /// Hidden on this slot (`off`), kept in the list to show again.
    var hidden: Bool?

    enum CodingKeys: String, CodingKey {
        case type, shape, x, y
        case width = "w"
        case height = "h"
        case color
        case layer = "z"
        case rotation = "rot"
        case opacity = "op"
        case value
        case source = "src"
        case stars, star, ink, art, anchor, avoid, span
        case hidden = "off"
    }

    enum Kind: String, Codable, Hashable, Sendable, CaseIterable {
        case shape
        /// A value with laurel branches on both sides, and stars.
        case laurel
        /// A value on a starburst.
        case badge
        /// A prop or a hand-drawn mark (`art` names it).
        case art
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
        /// A drawn line above each review.
        case rule
        case moon
        /// A hand's palm under the phone.
        case palm
        case thumb
        /// The fingers wrapped round the phone's edge.
        case fingers
    }

    enum RatingSource: String, Codable, Hashable, Sendable, CaseIterable {
        /// The App Store's average in the language's country.
        case store
        /// The value typed in.
        case custom
    }

    enum Layer: String, Codable, Hashable, Sendable, CaseIterable {
        /// Behind the device.
        case back
        /// Over the device and the band, under the caption.
        case front
    }

    enum Anchor: String, Codable, Hashable, Sendable, CaseIterable {
        /// `y` is measured from the caption box's bottom.
        case caption = "cap"
        /// At the end of the headline's first line, centered on it.
        case firstLineEnd = "l1end"
    }

    enum Avoidance: String, Codable, Hashable, Sendable, CaseIterable {
        /// Moves below the caption.
        case down
        /// Narrows to start past the text.
        case squeeze
        /// Isn't drawn.
        case hide
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

    /// A prop or a mark; `color` tints only the marks drawn in one color.
    static func art(
        _ art: TemplateArt, x: Double, y: Double, width: Double, height: Double, color: String = "#FFFFFF", layer: Layer = .front,
        rotation: Double? = nil, anchor: Anchor? = nil, avoid: Avoidance? = nil, span: Int? = nil
    ) -> TemplateDecoration {
        TemplateDecoration(
            type: .art, x: x, y: y, width: width, height: height, color: color, layer: layer, rotation: rotation,
            art: art, anchor: anchor, avoid: avoid, span: span
        )
    }

    /// Laurels and badges show a rating, which must be true.
    var isRating: Bool { type == .laurel || type == .badge }

    /// A laurel that shows the App Store's rating in each country rather
    /// than a typed value.
    var showsStoreRating: Bool { type == .laurel && (source ?? .store) == .store }

    var isHidden: Bool { hidden ?? false }

    /// Whether the color picker changes how it looks: not on a multi-color
    /// prop.
    var takesColor: Bool { type != .art || art?.isTintable == true }

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

    /// "Rating laurel", "Badge", "Sparkle", "Ribbon", "Game controller"…
    var title: String {
        switch type {
        case .laurel: String(localized: "Rating laurel")
        case .badge: String(localized: "Badge")
        case .shape: shape?.title ?? String(localized: "Shape")
        case .art: art?.title ?? String(localized: "Prop")
        }
    }
}

extension TemplateDecoration {
    /// A prop may leave its color out (white) and its layer (front).
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(Kind.self, forKey: .type)
        shape = try container.decodeIfPresent(Shape.self, forKey: .shape)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        let color = try container.decodeIfPresent(String.self, forKey: .color)
        guard let color = color ?? (type == .art ? "#FFFFFF" : nil) else {
            throw DecodingError.keyNotFound(CodingKeys.color, DecodingError.Context(codingPath: container.codingPath, debugDescription: "No color"))
        }
        self.color = color
        let layer = try container.decodeIfPresent(Layer.self, forKey: .layer)
        guard let layer = layer ?? (type == .art ? .front : nil) else {
            throw DecodingError.keyNotFound(CodingKeys.layer, DecodingError.Context(codingPath: container.codingPath, debugDescription: "No layer"))
        }
        self.layer = layer
        rotation = try container.decodeIfPresent(Double.self, forKey: .rotation)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        source = try container.decodeIfPresent(RatingSource.self, forKey: .source)
        stars = try container.decodeIfPresent(Bool.self, forKey: .stars)
        star = try container.decodeIfPresent(String.self, forKey: .star)
        ink = try container.decodeIfPresent(String.self, forKey: .ink)
        art = try container.decodeIfPresent(TemplateArt.self, forKey: .art)
        anchor = try container.decodeIfPresent(Anchor.self, forKey: .anchor)
        avoid = try container.decodeIfPresent(Avoidance.self, forKey: .avoid)
        span = try container.decodeIfPresent(Int.self, forKey: .span)
        hidden = try container.decodeIfPresent(Bool.self, forKey: .hidden)
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
        case .rule: String(localized: "Rule")
        case .moon: String(localized: "Moon")
        case .palm: String(localized: "Palm")
        case .thumb: String(localized: "Thumb")
        case .fingers: String(localized: "Fingers")
        }
    }
}
