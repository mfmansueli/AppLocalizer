//
//  AppLookProfile+MCP.swift
//  AppLocalizer
//

import Foundation

/// `report_app_support`'s look: the app's theme, icon and design language
/// as the project has them, and the header scene template recommended from
/// them. The run's designers get it back in get_design_brief's
/// `aboutTheApp.look` and in the header and search prompts.
extension AppLookProfile {
    static let mcpSchema: JSONValue = [
        "type": "object",
        "description": """
        The app's look, read from the project: what it does, who it's for and when they use it, theme colors and fonts, dark \
        mode, the icon in a sentence, its design language (personality, motifs, what it avoids, from the design docs and the \
        theme code), and the header scene template you recommend for its App Store header with why. Every screenshot, header, \
        search and App Preview design in Autopilot starts from it.
        """,
        "properties": [
            "accentColor": ["type": "string", "description": "The accent color, hex."],
            "themeColors": ["type": "array", "items": ["type": "string"], "description": "Other theme colors, hex, the main ones first."],
            "fonts": [
                "type": "array", "items": ["type": "string"],
                "description": "The fonts the app uses, with how (\"SF Pro Bold, −2% tracking for titles\").",
            ],
            "supportsDarkMode": ["type": "boolean"],
            "whatItDoes": ["type": "string", "description": "What the app does and its key features, in one line."],
            "iconDescription": ["type": "string", "description": "The icon's shape, subject and style, in one sentence."],
            "audience": ["type": "string", "description": "Who it's for, in one sentence."],
            "usageMoment": ["type": "string", "description": "When and where people use it, in one sentence."],
            "personality": [
                "type": "string",
                "description": "The brand's character in one or two sentences, in the design docs' own words when they have them.",
            ],
            "motifs": [
                "type": "array", "items": ["type": "string"],
                "description": "The images, shapes and textures the app's own design is built from (\"drifting mist bands\", \"a low ember sun\").",
            ],
            "avoid": [
                "type": "array", "items": ["type": "string"],
                "description": "What the design docs or the brand rule out (\"rainbow gradients\", \"stock photos of couples\").",
            ],
            "designSource": [
                "type": "string",
                "description": "The files you read it from (\"DESIGN.md, Theme/Palette.swift, Assets.xcassets/AccentColor\").",
            ],
            "headerTemplate": [
                "type": "string", "enum": .array(AutopilotHeaderTemplate.allCases.map { .string($0.rawValue) }),
                "description": "The scene template you recommend for the header.",
            ],
            "headerReason": ["type": "string", "description": "Why, in one sentence the person reads in the plan."],
        ],
    ]

    /// The look in `object`; nil when it isn't sent or says nothing.
    static func mcp(_ object: [String: JSONValue]?) -> AppLookProfile? {
        guard let object else { return nil }
        func trimmed(_ value: JSONValue?) -> String? {
            guard let text = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
            return text
        }
        func text(_ key: String) -> String? { trimmed(object[key]) }
        func list(_ key: String) -> [String] { (object[key]?.arrayValue ?? []).compactMap(trimmed) }
        func optionalList(_ key: String) -> [String]? {
            let items = list(key)
            return items.isEmpty ? nil : items
        }
        let look = AppLookProfile(
            accentColor: text("accentColor"), themeColors: list("themeColors"), fonts: list("fonts"),
            supportsDarkMode: object["supportsDarkMode"]?.boolValue, whatItDoes: text("whatItDoes"), iconDescription: text("iconDescription"),
            audience: text("audience"), usageMoment: text("usageMoment"),
            personality: text("personality"), motifs: optionalList("motifs"), avoid: optionalList("avoid"),
            designSource: text("designSource"),
            headerTemplate: text("headerTemplate").flatMap { AutopilotHeaderTemplate(rawValue: $0.lowercased()) },
            headerReason: text("headerReason")
        )
        return look.isEmpty ? nil : look
    }

    /// get_design_brief's `aboutTheApp.look`: everything the scan found,
    /// for the designers.
    var mcpJSON: JSONValue {
        var json: [String: JSONValue] = [:]
        func put(_ key: String, _ value: String?) {
            if let value, !value.isEmpty { json[key] = .string(value) }
        }
        func put(_ key: String, _ values: [String]?) {
            if let values, !values.isEmpty { json[key] = .array(values.map(JSONValue.string)) }
        }
        put("whatItDoes", whatItDoes)
        put("audience", audience)
        put("usageMoment", usageMoment)
        put("personality", personality)
        put("motifs", motifs)
        put("avoid", avoid)
        put("accentColor", accentColor)
        put("themeColors", themeColors)
        put("fonts", fonts)
        put("iconDescription", iconDescription)
        put("designSource", designSource)
        if let supportsDarkMode { json["supportsDarkMode"] = .bool(supportsDarkMode) }
        return .object(json)
    }

    /// get_capture_plan's `appLook`: what the designers will know of the
    /// app, and, when the scan is missing or older than the design
    /// language, how to read it before capturing.
    static func mcpCapturePlanNote(_ look: AppLookProfile?) -> JSONValue {
        guard let look, look.isComplete else {
            var json: [String: JSONValue] = [
                "status": .string(look == nil ? "missing" : "incomplete"),
                "do": .string(scanHow),
            ]
            if let look { json["sofar"] = look.mcpJSON }
            return .object(json)
        }
        return [
            "status": "known",
            "look": look.mcpJSON,
            "do": "AppLocalizer already has the app's look. Send report_app_support with look again only if the project says otherwise.",
        ]
    }

    /// How to read the look, for get_capture_plan and get_design_brief.
    static let scanHow = """
    Before choosing screens, read the app's look and design language in the project, because every screenshot, header, \
    search and App Preview design in this run starts from it: design docs (DESIGN*.md, docs/design, BRAND*, the README's \
    design section), the theme in code (palette or color tokens, the asset catalog's AccentColor, fonts and their \
    tracking), the app icon, onboarding copy and the App Store description. Then send report_app_support for this app \
    with languages (every language in its string catalogs), devices and look: whatItDoes, audience, usageMoment, \
    personality (in the docs' own words), motifs (the images the design is built from), avoid (what the docs rule out, \
    and the category's clichés the brand stays away from), accentColor, themeColors, fonts, supportsDarkMode, \
    iconDescription, designSource, and the headerTemplate you recommend with headerReason.
    """
}
