//
//  AppAnswer.swift
//  AppLocalizer
//

import Foundation

/// The assistant's answer to an `AppQuestion`.
struct AppAnswer: Codable, Hashable, Sendable {
    /// Nil when the project doesn't say: it isn't asked again until the
    /// answer is old.
    var text: String?
    var answeredAt: Date
    /// "Claude Code".
    var answeredBy: String?
}
