//
//  TemplateFonts.swift
//  AppLocalizer
//

import Foundation

/// `fonts`: the display font and a fallback per script for captions it
/// can't draw. A script without a fallback (`null` or missing) fails the
/// glyph check instead of drawing empty boxes.
struct TemplateFonts: Codable, Hashable, Sendable {
    var display: String
    var fallback: [ScreenshotScript: String]

    init(display: String, fallback: [ScreenshotScript: String]) {
        self.display = display
        self.fallback = fallback
    }

    private enum CodingKeys: String, CodingKey {
        case display, fallback
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        display = try container.decode(String.self, forKey: .display)
        let raw = try container.decodeIfPresent([String: String?].self, forKey: .fallback) ?? [:]
        var fallback: [ScreenshotScript: String] = [:]
        for (key, value) in raw {
            guard let script = ScreenshotScript(rawValue: key) else {
                throw DecodingError.dataCorruptedError(forKey: .fallback, in: container, debugDescription: "Unknown script “\(key)”")
            }
            if let value { fallback[script] = value }
        }
        self.fallback = fallback
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(display, forKey: .display)
        let raw = Dictionary(uniqueKeysWithValues: fallback.map { ($0.key.rawValue, $0.value) })
        try container.encode(raw, forKey: .fallback)
    }

    /// The fallback the template names for `script`, if any.
    func fallback(for script: ScreenshotScript) -> String? {
        fallback[script]
    }

    /// System fonts for every script but Latin, which the display font
    /// draws.
    static let systemFallbacks: [ScreenshotScript: String] = [
        .cyrillic: "SF Pro Display", .greek: "SF Pro Display", .vietnamese: "SF Pro Display",
        .arabic: "SF Arabic", .hebrew: "SF Hebrew", .japanese: "Hiragino Sans",
        .simplifiedChinese: "PingFang SC", .traditionalChinese: "PingFang TC", .korean: "Apple SD Gothic Neo",
        .thai: "Thonburi", .devanagari: "Kohinoor Devanagari",
    ]
}
