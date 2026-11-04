//
//  AppLookProfile+MCP.swift
//  AppLocalizer
//

import Foundation

/// `report_app_support`'s look: the app's theme and icon as the project
/// has them, and the header scene template recommended from them.
extension AppLookProfile {
    static let mcpSchema: JSONValue = [
        "type": "object",
        "description": """
        The app's look, read from the project: what it does, theme colors and fonts, dark mode, the icon in a sentence, who it's for, \
        when people use it, and the header scene template you recommend for its App Store header with why.
        """,
        "properties": [
            "accentColor": ["type": "string", "description": "The accent color, hex."],
            "themeColors": ["type": "array", "items": ["type": "string"], "description": "Other theme colors, hex."],
            "fonts": ["type": "array", "items": ["type": "string"], "description": "The fonts the app uses."],
            "supportsDarkMode": ["type": "boolean"],
            "whatItDoes": ["type": "string", "description": "What the app does and its key features, in one line."],
            "iconDescription": ["type": "string", "description": "The icon's shape, subject and style, in one sentence."],
            "audience": ["type": "string", "description": "Who it's for, in one sentence."],
            "usageMoment": ["type": "string", "description": "When and where people use it, in one sentence."],
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
        let look = AppLookProfile(
            accentColor: text("accentColor"), themeColors: list("themeColors"), fonts: list("fonts"),
            supportsDarkMode: object["supportsDarkMode"]?.boolValue, whatItDoes: text("whatItDoes"), iconDescription: text("iconDescription"),
            audience: text("audience"), usageMoment: text("usageMoment"),
            headerTemplate: text("headerTemplate").flatMap { AutopilotHeaderTemplate(rawValue: $0.lowercased()) },
            headerReason: text("headerReason")
        )
        return look.isEmpty ? nil : look
    }
}
