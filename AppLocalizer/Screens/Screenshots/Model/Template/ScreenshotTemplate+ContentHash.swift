//
//  ScreenshotTemplate+ContentHash.swift
//  AppLocalizer
//

import CryptoKit
import Foundation

extension ScreenshotTemplate {
    /// A stable hash of everything that changes how renders look: the
    /// canonical JSON (sorted keys) without `version` and `name`. Re-saving
    /// or restoring a template without changes keeps the hash, so its
    /// renders keep their render keys and nothing is pushed again.
    var contentHash: String {
        var content = self
        content.version = 0
        content.name = ""
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = (try? encoder.encode(content)) ?? Data()
        return SHA256.hash(data: data).prefix(12).map { String(format: "%02x", $0) }.joined()
    }
}
