//
//  ListingProposalOutcome.swift
//  AppLocalizer
//

import Foundation

/// What happened to an assistant's `propose_listing_text` call.
enum ListingProposalOutcome: Hashable, Sendable {
    /// Queued as a pending change tagged with the client.
    case queued
    /// Queued next to a change of yours; you pick one in Review & Push.
    case conflict
    /// Same as the current value; nothing to queue.
    case unchanged
    case refused(ListingProposalRefusal)

    /// MCP's `status` field: "queued" or "refused".
    var status: String {
        switch self {
        case .queued, .conflict, .unchanged: "queued"
        case .refused: "refused"
        }
    }
}
