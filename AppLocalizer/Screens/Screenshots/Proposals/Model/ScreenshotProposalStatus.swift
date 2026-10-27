//
//  ScreenshotProposalStatus.swift
//  AppLocalizer
//

import Foundation

/// Where a proposal stands. "Stale" isn't stored: it's a waiting template
/// proposal based on an older version (`ScreenshotProposal.isStale`).
enum ScreenshotProposalStatus: String, Codable, Hashable, Sendable {
    case waiting
    case accepted
    /// Some captions accepted, the rest rejected.
    case partlyAccepted
    case rejected

    /// `list_proposals`' word for it: pending, accepted, partial or
    /// rejected (stale is decided by the caller).
    var toolValue: String {
        switch self {
        case .waiting: "pending"
        case .accepted: "accepted"
        case .partlyAccepted: "partial"
        case .rejected: "rejected"
        }
    }
}
