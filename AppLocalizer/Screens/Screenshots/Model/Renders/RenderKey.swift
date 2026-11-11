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

    /// `store` is what the App Store put in the render (a laurel's rating,
    /// the reviews quoted), so a new rating or review renders again; left
    /// out, the key is the one it was before.
    init(
        templateHash: String, locale: String, displayType: ScreenshotDisplayType, slot: Int, caption: ScreenshotCaption?, captureID: String?,
        store: String? = nil
    ) {
        var parts = [templateHash, locale, displayType.rawValue, "\(slot)", caption?.renderText ?? "", captureID ?? "-"]
        if let store { parts.append(store) }
        if let frame = Self.frameRevision(for: displayType) { parts.append(frame) }
        let digest = SHA256.hash(data: Data(parts.joined(separator: "\u{1E}").utf8))
        rawValue = digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    /// Changes when a device's frame is drawn differently, so its
    /// screenshots render again and count as changed; nil keeps the keys a
    /// device always had. iPhone Duo's 2: the folded phone's hinge and
    /// corners from Apple's masks.
    static func frameRevision(for display: ScreenshotDisplayType) -> String? {
        display == .iPhoneDuo ? "frame-2" : nil
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
