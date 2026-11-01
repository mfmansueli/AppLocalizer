//
//  TemplateFieldRule.swift
//  AppLocalizer
//

import Foundation

/// What a template field accepts. `TemplateSchema` assigns one to every
/// writable path.
enum TemplateFieldRule: Hashable, Sendable {
    /// A number in a range; `unit` is how a refusal names it ("u", "°", "").
    case number(ClosedRange<Double>, unit: String)
    case integer(ClosedRange<Int>)
    case boolean
    /// One of a list of strings.
    case choice([String])
    /// A hex color (`#7A80FF`) or `rgb()`/`rgba()`.
    case color
    /// A list of colors with this many entries.
    case colors(ClosedRange<Int>)
    /// An installed font.
    case font
    /// `null`, or a font that draws `script`.
    case fallbackFont(ScreenshotScript)
    /// Non-empty text.
    case text
    /// `{ rz, ry, rx }` in degrees.
    case tilt
    /// `{ on: "first" | "last", weight?, font?, italic?, color? }`.
    case emphasis
    /// `{ color, pad?, rot?, radius?, shadow? }`.
    case highlight
    /// A CSS shadow in em: "0 0.05em 0 rgba(18,10,70,0.5)".
    case shadow
    /// A list of shapes, laurels and badges.
    case decorations
    /// A whole `bg` (solid or linear), for a slot's own background.
    case background
}
