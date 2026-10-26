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
}
