//
//  ListingVersionState.swift
//  AppLocalizer
//

import Foundation

/// An App Store version's state. Raw values are App Store Connect's
/// `appVersionState` values; only the ones the Store Page cares about are
/// listed, and anything else reads as `.inReview` (read-only).
enum ListingVersionState: String, Hashable, Sendable, Codable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case developerRejected = "DEVELOPER_REJECTED"
    case rejected = "REJECTED"
    case metadataRejected = "METADATA_REJECTED"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case pendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE"
    case readyForDistribution = "READY_FOR_DISTRIBUTION"

    init(apiValue: String) {
        self = ListingVersionState(rawValue: apiValue) ?? .inReview
    }

    var title: String {
        switch self {
        case .prepareForSubmission: String(localized: "Prepare for Submission")
        case .developerRejected: String(localized: "Developer Rejected")
        case .rejected: String(localized: "Rejected")
        case .metadataRejected: String(localized: "Metadata Rejected")
        case .waitingForReview: String(localized: "Waiting for Review")
        case .inReview: String(localized: "In Review")
        case .pendingDeveloperRelease: String(localized: "Pending Developer Release")
        case .readyForDistribution: String(localized: "Ready for Distribution")
        }
    }

    /// App Store Connect accepts version-level metadata changes only before
    /// the version is submitted, or after it's rejected.
    var isEditable: Bool {
        switch self {
        case .prepareForSubmission, .developerRejected, .rejected, .metadataRejected: true
        case .waitingForReview, .inReview, .pendingDeveloperRelease, .readyForDistribution: false
        }
    }

    /// On the App Store now.
    var isLive: Bool { self == .readyForDistribution }
}
