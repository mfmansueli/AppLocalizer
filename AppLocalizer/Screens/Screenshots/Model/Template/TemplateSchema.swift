//
//  TemplateSchema.swift
//  AppLocalizer
//

import Foundation

/// Every field an operation may replace, with what it accepts. Paths are
/// as in README §3. `schema`, `id`, `version` and `starter` are set by
/// AppLocalizer and can't be proposed.
enum TemplateSchema {
    static let rules: [String: TemplateFieldRule] = {
        var rules: [String: TemplateFieldRule] = [
            "name": .text,
            "canvas.iphone": .choice(ScreenshotOrientation.allCases.map(\.rawValue)),
            "canvas.ipad": .choice(ScreenshotOrientation.allCases.map(\.rawValue)),
            "canvas.duo": .choice(ScreenshotOrientation.allCases.map(\.rawValue)),
            "bg.kind": .choice(TemplateBackground.Kind.allCases.map(\.rawValue)),
            "bg.angle": .number(0...360, unit: "°"),
            "bg.stops": .colors(1...6),
            "bg.image": .text,
            "device.show": .boolean,
            "device.width": .number(0.6...0.9, unit: ""),
            "device.color": .color,
            "device.offset": .number(0...0.2, unit: ""),
            "device.bleed": .number(0...0.2, unit: ""),
            "device.tilt": .tilt,
            "device.dx": .number(-0.5...0.5, unit: ""),
            "device.dy": .number(-0.5...0.5, unit: ""),
            "caption.placement": .choice(TemplateCaption.Placement.allCases.map(\.rawValue)),
            "caption.align": .choice(TemplateCaption.Alignment.allCases.map(\.rawValue)),
            "caption.gap": .number(0...0.1, unit: ""),
            "caption.ink": .color,
            "caption.subInk": .color,
            "caption.band.color": .color,
            "caption.band.pos": .choice(TemplateBand.Position.allCases.map(\.rawValue)),
            "fit.shrink": .boolean,
            "fit.hyphenate": .boolean,
            "rtl.mirror": .boolean,
            "safe.top": .number(0...0.25, unit: ""),
            "safe.side": .number(0...0.25, unit: ""),
            "safe.bottom": .number(0...0.25, unit: ""),
            "fonts.display": .font,
            "caption.headline.upper": .boolean,
            "caption.headline.italic": .boolean,
            "caption.headline.shadow": .shadow,
            "caption.headline.emph": .emphasis,
            "caption.headline.mark": .highlight,
            "caption.subhead.italic": .boolean,
            "deco": .decorations,
        ]
        for (block, sizes) in [("headline", 40.0...240), ("subhead", 24.0...120)] {
            rules["caption.\(block).font"] = .font
            rules["caption.\(block).weight"] = .integer(100...900)
            rules["caption.\(block).size"] = .number(sizes, unit: "u")
            rules["caption.\(block).min"] = .number(sizes, unit: "u")
            rules["caption.\(block).lh"] = .number(0.8...2, unit: "")
            rules["caption.\(block).maxLines"] = .integer(1...3)
            rules["caption.\(block).tracking"] = .number(-0.1...0.1, unit: "em")
        }
        for script in ScreenshotScript.allCases {
            rules["fonts.fallback.\(script.rawValue)"] = .fallbackFont(script)
        }
        return rules
    }()

    /// Fields AppLocalizer sets itself.
    static let readOnlyPaths: Set = ["schema", "id", "version", "starter"]

    /// Fields a template may leave out: replacing one with `null` removes
    /// it, and it reads as off, flat or none.
    static let optionalPaths: Set = [
        "device.tilt", "device.dx", "device.dy", "caption.headline.upper", "caption.headline.italic",
        "caption.headline.shadow", "caption.headline.emph", "caption.headline.mark", "caption.subhead.italic",
        "caption.headline.tracking", "caption.subhead.tracking", "deco",
    ]

    /// Fields only a slot can override: its own background.
    static let overrideOnlyRules: [String: TemplateFieldRule] = ["bg": .background]

    static func rule(for path: String) -> TemplateFieldRule? {
        rules[path]
    }

    /// The rule for a slot override of `path`: any field but the name and
    /// the canvas, which hold for the whole set, plus a whole background.
    static func overrideRule(for path: String) -> TemplateFieldRule? {
        guard path != "name", !path.hasPrefix("canvas.") else { return nil }
        return rules[path] ?? overrideOnlyRules[path]
    }

    /// The writable fields directly under `prefix` (`caption.headline` →
    /// font, weight, size…), for a refusal that suggests the right name.
    static func fields(under prefix: String) -> [String] {
        let start = prefix.isEmpty ? "" : prefix + "."
        let names = rules.keys.compactMap { path -> String? in
            guard path.hasPrefix(start) else { return nil }
            return path.dropFirst(start.count).split(separator: ".").first.map(String.init)
        }
        return Array(Set(names)).sorted()
    }
}
