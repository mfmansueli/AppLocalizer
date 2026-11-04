//
//  ArtworkPromptLogEntry.swift
//  AppLocalizer
//

import Foundation

/// One line of the prompt log: a prompt handed to the design AI, what it
/// sent back, or a page render_artwork rendered. With the prompt's id,
/// version and hash and the inputs' hashes, any page can be traced, run
/// again, or sent to another design AI.
struct ArtworkPromptLogEntry: Codable, Hashable, Sendable {
    enum Event: String, Codable, Hashable, Sendable {
        /// next_step handed a filled prompt.
        case prompt
        /// propose_artwork_concept or revise_artwork_concept.
        case answer
        /// render_artwork.
        case render
    }

    var loggedAt: Date
    var event: Event
    var app: String
    var run: String
    /// The assistant that asked or answered ("Claude Code").
    var provider: String
    /// The design source it designs with ("Claude Design").
    var designSource: String?
    /// "artwork-concepts-free".
    var promptID: String?
    /// "v3".
    var promptVersion: String?
    /// The filled prompt's SHA-256.
    var promptHash: String?
    /// The concept (or concepts) it's about.
    var about: String?
    /// The placeholders' values, as filled.
    var inputs: [String: String]?
    /// Each input file's SHA-256, by name ("icon", "capture 2", a
    /// reference's file name).
    var files: [String: String]?
    /// What came back: the concept's JSON, each page's SHA-256.
    var outputs: [String: String]?
    /// render_artwork's findings, or why a page was refused.
    var checks: [String]?
}
