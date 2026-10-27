//
//  ListingAssistantProposal.swift
//  AppLocalizer
//

import Foundation

/// A value proposed by a connected AI assistant, e.g. Claude Code.
struct ListingAssistantProposal: Hashable, Sendable {
    /// The client's display name, e.g. "Claude Code".
    let client: String
    let value: String
}
