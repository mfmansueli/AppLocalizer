//
//  TemplateHighlight.swift
//  AppLocalizer
//

import Foundation

/// `caption.headline.mark`: a marker bar behind each wrapped line of the
/// headline, rotated alternately. Lengths are in em of the headline size;
/// the box the caption fits in shrinks by the padding on both sides.
struct TemplateHighlight: Codable, Hashable, Sendable {
    var color: String
    /// Horizontal padding around the line's text, in em (`pad`). 0.2 when
    /// left out.
    var padding: Double?
    /// Degrees (`rot`); odd lines turn the other way, and right-to-left
    /// locales mirror it.
    var rotation: Double?
    /// Corner radius, in em.
    var radius: Double?
    /// A CSS box shadow behind the bar, e.g. "0.07em 0.07em 0 #4B10A8".
    var shadow: String?

    static let defaultPadding = 0.2

    enum CodingKeys: String, CodingKey {
        case color
        case padding = "pad"
        case rotation = "rot"
        case radius, shadow
    }

    var horizontalPadding: Double { padding ?? Self.defaultPadding }
}
