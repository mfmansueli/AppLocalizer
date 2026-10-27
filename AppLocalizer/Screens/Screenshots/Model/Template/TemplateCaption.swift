//
//  TemplateCaption.swift
//  AppLocalizer
//

import Foundation

/// `caption`: where the caption goes and how it's set.
struct TemplateCaption: Codable, Hashable, Sendable {
    var placement: Placement
    var align: Alignment
    /// Space between the caption box and the device, as a fraction of
    /// the canvas height.
    var gap: Double
    /// Headline color: hex or `rgba(…)`.
    var ink: String
    /// Subhead color.
    var subInk: String
    var band: TemplateBand
    var headline: TemplateTextStyle
    var subhead: TemplateTextStyle

    /// Above the device, or in a solid band while the capture fills the
    /// canvas (the device is ignored then).
    enum Placement: String, Codable, Hashable, Sendable, CaseIterable {
        case above
        case band
    }

    /// `start` is the reading direction's start: left in English, right
    /// in Arabic.
    enum Alignment: String, Codable, Hashable, Sendable, CaseIterable {
        case center
        case start
    }
}
