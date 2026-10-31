//
//  AutopilotRevisionRequest.swift
//  AppLocalizer
//

import Foundation

/// "Ask for changes": a note for the design AI, sent back with
/// `next_step` until a revised direction arrives.
struct AutopilotRevisionRequest: Codable, Hashable, Sendable {
    var note: String
    var askedAt: Date
}
