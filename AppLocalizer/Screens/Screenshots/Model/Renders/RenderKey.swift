//
//  RenderKey.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

/// Identifies one render's content: the template's content hash, the
/// caption text and the capture, plus what else changes the pixels (the
/// display type, the slot, whose layout the template may override, and the
/// locale, which picks line breaking, fonts and direction). Equal keys
/// mean identical PNGs, so the render cache and the "is it live?" question
/// both use it.
struct RenderKey: Codable, Hashable, Sendable, CustomStringConvertible {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(templateHash: String, locale: String, displayType: ScreenshotDisplayType, slot: Int, caption: ScreenshotCaption?, captureID: String?) {
        let parts = [templateHash, locale, displayType.rawValue, "\(slot)", caption?.renderText ?? "", captureID ?? "-"]
        let digest = SHA256.hash(data: Data(parts.joined(separator: "\u{1E}").utf8))
        rawValue = digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    init(from decoder: any Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var description: String { rawValue }
}
