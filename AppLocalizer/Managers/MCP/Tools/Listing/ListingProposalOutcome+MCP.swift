//
//  ListingProposalOutcome+MCP.swift
//  AppLocalizer
//

import Foundation

extension ListingProposalOutcome {
    /// Queued for review, alone or next to the person's own change.
    var isQueued: Bool {
        switch self {
        case .queued, .conflict: true
        case .unchanged, .refused: false
        }
    }

    var isRefused: Bool {
        if case .refused = self { return true }
        return false
    }
}
