//
//  TemplateStarter.swift
//  AppLocalizer
//

import Foundation

/// The three starting points the first-run picker and Starter Templates…
/// offer. Each makes a complete template; switching keeps captions and
/// captures.
enum TemplateStarter: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    /// A headline over a framed device, on brand colors.
    case above
    /// The capture fills the screenshot; a solid band carries the caption.
    case band
    /// One background runs across every slot.
    case panorama

    var id: String { rawValue }

    var title: String {
        switch self {
        case .above: String(localized: "Caption above device")
        case .band: String(localized: "Full-bleed with caption band")
        case .panorama: String(localized: "Panorama")
        }
    }

    var summary: String {
        switch self {
        case .above: String(localized: "A headline over a framed device, on your brand colors. Works for almost any app.")
        case .band: String(localized: "The capture fills the screenshot and a solid band carries the caption. Shows the most of your interface.")
        case .panorama: String(localized: "One background runs across every slot, so the set reads as one scene when people swipe.")
        }
    }
}
