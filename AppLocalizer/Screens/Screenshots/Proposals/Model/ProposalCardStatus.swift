//
//  ProposalCardStatus.swift
//  AppLocalizer
//

import Foundation

/// A proposal card's status pill: Waiting, Stale, Accepted, Partly
/// accepted or Rejected.
enum ProposalCardStatus: Hashable, Sendable {
    case waiting
    /// A waiting template proposal based on an older version.
    case stale
    case accepted
    case partlyAccepted
    case rejected

    init(_ proposal: ScreenshotProposal, currentVersion: Int?) {
        switch proposal.status {
        case .waiting: self = currentVersion.map { proposal.isStale(currentVersion: $0) } == true ? .stale : .waiting
        case .accepted: self = .accepted
        case .partlyAccepted: self = .partlyAccepted
        case .rejected: self = .rejected
        }
    }

    var title: String {
        switch self {
        case .waiting: String(localized: "Waiting")
        case .stale: String(localized: "Stale")
        case .accepted: String(localized: "Accepted")
        case .partlyAccepted: String(localized: "Partly accepted")
        case .rejected: String(localized: "Rejected")
        }
    }

    var style: PillStyle {
        switch self {
        case .waiting: .accent
        case .stale: .warning
        case .accepted, .partlyAccepted: .neutral
        case .rejected: .outline
        }
    }
}
