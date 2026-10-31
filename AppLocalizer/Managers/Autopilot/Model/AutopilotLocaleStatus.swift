//
//  AutopilotLocaleStatus.swift
//  AppLocalizer
//

import Foundation

/// One language's row in Localize and check.
enum AutopilotLocaleStatus: Codable, Hashable, Sendable {
    case waiting
    case checking
    /// Every caption fits; `note` says how, e.g. "Hiragino Sans for
    /// Japanese" or "mirrored for right-to-left".
    case fits(note: String?)
    /// Captions too long, sent to the assistant to shorten.
    case shortening(count: Int)

    var isDone: Bool {
        if case .fits = self { return true }
        return false
    }
}
