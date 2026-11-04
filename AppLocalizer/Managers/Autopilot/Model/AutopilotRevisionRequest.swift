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
    /// The header concepts the note is for (`revise_artwork_concept`);
    /// nil when it's only about the directions.
    var conceptIDs: [String]?
    /// The note is about the screenshot directions too; nil (notes from
    /// before) is yes.
    var forDirections: Bool?

    /// It goes to the directions.
    var asksDirections: Bool { forDirections ?? true }

    /// The concepts it goes to.
    var askedConcepts: [String] { conceptIDs ?? [] }
}
