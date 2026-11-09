//
//  RetentionSuggestion.swift
//  AppLocalizer
//

import Foundation

/// A shorter wording an assistant suggested for one language of a message
/// that runs over Apple's limits; Use Shorter Version takes it.
struct RetentionSuggestion: Hashable, Codable, Sendable {
    var messageID: String
    var locale: String
    /// Nil keeps the header.
    var header: String?
    var body: String
    /// "Claude Code".
    var client: String

    /// The text with the suggestion in it.
    func applied(to text: RetentionText) -> RetentionText {
        RetentionText(header: header ?? text.header, body: body, origin: .assistant(client: client))
    }
}
