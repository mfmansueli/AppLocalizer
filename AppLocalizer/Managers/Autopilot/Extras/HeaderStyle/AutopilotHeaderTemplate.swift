//
//  AutopilotHeaderTemplate.swift
//  AppLocalizer
//

import Foundation

/// The six scene templates the header and search concepts can start
/// from (the plan's Header style). Claude Design keeps a template's scene
/// type, layer recipe and loop, and chooses the subject, colors and
/// details for the app. The raw values are the prompts' template ids.
enum AutopilotHeaderTemplate: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case night
    case land
    case window
    case horizon
    case hero
    case pattern

    var id: String { rawValue }

    /// The most a plan picks; a fourth replaces the last.
    static let maximumPicks = 3

    /// "Day to Night".
    var name: String {
        switch self {
        case .night: String(localized: "Day to Night")
        case .land: String(localized: "Layered Landscape")
        case .window: String(localized: "Window View")
        case .horizon: String(localized: "Horizon")
        case .hero: String(localized: "Hero Object")
        case .pattern: String(localized: "Brand Pattern")
        }
    }

    /// "Open sky, from sun to moon and back".
    var summary: String {
        switch self {
        case .night: String(localized: "Open sky, from sun to moon and back")
        case .land: String(localized: "Hills, forest or mountains in depth")
        case .window: String(localized: "A frame, with the sky changing behind it")
        case .horizon: String(localized: "Water or a skyline, with something passing")
        case .hero: String(localized: "One large object that stands for the app")
        case .pattern: String(localized: "Abstract shapes in the brand’s colors")
        }
    }

    /// The apps it suits: "Sleep, journaling, weather, calm".
    var fits: String {
        switch self {
        case .night: String(localized: "Sleep, journaling, weather, calm")
        case .land: String(localized: "Outdoor, health, travel, wellness")
        case .window: String(localized: "Travel, home, productivity")
        case .horizon: String(localized: "Games, travel, maps, sport")
        case .hero: String(localized: "Utilities, finance, tools")
        case .pattern: String(localized: "Apps with no physical metaphor")
        }
    }

    /// How it moves as a loop.
    var loop: String {
        switch self {
        case .night: String(localized: "The sun sets, the moon rises, stars come out, dawn returns")
        case .land: String(localized: "The layers drift at different speeds while the light changes")
        case .window: String(localized: "The sky behind the frame goes day, dusk, night, dawn")
        case .horizon: String(localized: "A boat or lights cross; light moves on the water")
        case .hero: String(localized: "A soft light sweeps across the object")
        case .pattern: String(localized: "Shapes drift and overlap slowly")
        }
    }

    /// "Open sky, from sun to moon and back · Fits sleep, journaling,
    /// weather, calm".
    var tileDetail: String {
        summary + " · " + String(localized: "Fits \(fits.lowercased())")
    }

    /// "Loop: the sun sets, the moon rises…".
    var loopLine: String {
        String(localized: "Loop: \(loop.prefix(1).lowercased() + loop.dropFirst())")
    }

    /// "From the Day to Night template".
    var sourceTitle: String {
        String(localized: "From the \(name) template")
    }

    /// The brief's "Day to Night (open sky, from sun to moon and back)".
    var briefTitle: String {
        "\(name) (\(summary.lowercased()))"
    }

    /// The first picks of a new plan: the recommended template, then the
    /// library's next ones.
    static func defaultPicks(recommended: AutopilotHeaderTemplate) -> [AutopilotHeaderTemplate] {
        Array(([recommended] + allCases.filter { $0 != recommended }).prefix(maximumPicks))
    }

    /// Picks `template`, or takes it out when it's picked: a fourth
    /// replaces the last.
    static func toggling(_ template: AutopilotHeaderTemplate, in picks: [AutopilotHeaderTemplate]) -> [AutopilotHeaderTemplate] {
        var picks = picks
        if let index = picks.firstIndex(of: template) {
            picks.remove(at: index)
            return picks
        }
        if picks.count >= maximumPicks { picks.removeLast() }
        picks.append(template)
        return picks
    }

    /// AppLocalizer's own guess from the App Store categories, until
    /// Claude Code recommends one from the scan.
    static func guess(categories: [String]) -> AutopilotHeaderTemplate {
        let words = categories.joined(separator: " ").lowercased()
        let table: [(AutopilotHeaderTemplate, [String])] = [
            (.horizon, ["game", "sport", "navigation", "map"]),
            (.window, ["travel", "productivity", "business", "news"]),
            (.land, ["health", "fitness", "medical", "outdoor"]),
            (.hero, ["finance", "utilit", "developer", "reference"]),
            (.night, ["lifestyle", "weather", "book", "music", "journal", "sleep"]),
        ]
        return table.first { _, keys in keys.contains { words.contains($0) } }?.0 ?? .night
    }
}
