//
//  AutopilotRevisionRequest.swift
//  AppLocalizer
//

import Foundation

/// "Ask for changes": a note for the design AI, sent back with
/// `next_step` until the last revised direction arrives.
struct AutopilotRevisionRequest: Codable, Hashable, Sendable {
    var note: String
    var askedAt: Date
    /// The directions revised so far for this note, while more are on the
    /// way (`revise_direction`'s `last: false`).
    var revisedIDs: [String]?
}
