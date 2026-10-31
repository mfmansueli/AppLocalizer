//
//  DesignProjectKind.swift
//  AppLocalizer
//

import Foundation

/// Where Autopilot's design comes from.
enum DesignProjectKind: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    /// A design system or project in Claude Design, reached through Claude.
    case claudeDesign
    /// Color and text styles, the logo and "Screenshot/…" frames.
    case figma
    /// `tokens.json`, fonts and an SVG logo in a folder on this Mac.
    case folder
    /// AppLocalizer's three starters, colored from the app icon.
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claudeDesign: String(localized: "Claude Design")
        case .figma: String(localized: "Figma file")
        case .folder: String(localized: "Brand folder")
        case .none: String(localized: "No design project")
        }
    }

    var summary: String {
        switch self {
        case .claudeDesign: String(localized: "Claude designs with your design system or project. Open any direction there to refine it.")
        case .figma: String(localized: "Reads color and text styles, the logo and screenshot frames from a Figma file.")
        case .folder: String(localized: "Design tokens, fonts and a logo in a folder on this Mac.")
        case .none: String(localized: "AppLocalizer’s starters, colored from the app icon.")
        }
    }

    /// The badge on a direction: "CD" or "AL".
    var monogram: String {
        switch self {
        case .claudeDesign: "CD"
        case .figma: "F"
        case .folder: "BF"
        case .none: "AL"
        }
    }

    /// A design AI makes the directions (not AppLocalizer's starters).
    var usesDesignAI: Bool { self != .none }
}
