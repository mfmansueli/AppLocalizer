//
//  ListingVersionState.swift
//  AppLocalizer
//

import Foundation

/// An App Store version's state. Raw values are App Store Connect's
/// `appVersionState` values: every one a version can be edited or read in.
/// `REPLACED_WITH_NEW_VERSION` is left out on purpose (replaced versions
/// aren't shown), and anything else reads as `.inReview` (read-only).
enum ListingVersionState: String, Hashable, Sendable, Codable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    /// Added to a review submission that hasn't been sent yet ("Add for
    /// Review" in App Store Connect).
    case readyForReview = "READY_FOR_REVIEW"
    case developerRejected = "DEVELOPER_REJECTED"
    case rejected = "REJECTED"
    case metadataRejected = "METADATA_REJECTED"
    case invalidBinary = "INVALID_BINARY"
    case waitingForExportCompliance = "WAITING_FOR_EXPORT_COMPLIANCE"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case accepted = "ACCEPTED"
    case pendingDeveloperRelease = "PENDING_DEVELOPER_RELEASE"
    case pendingAppleRelease = "PENDING_APPLE_RELEASE"
    case processingForDistribution = "PROCESSING_FOR_DISTRIBUTION"
    case readyForDistribution = "READY_FOR_DISTRIBUTION"

    init(apiValue: String) {
        self = ListingVersionState(rawValue: apiValue) ?? .inReview
    }

    var title: String {
        switch self {
        case .prepareForSubmission: String(localized: "Prepare for Submission")
        case .readyForReview: String(localized: "Ready for Review")
        case .developerRejected: String(localized: "Developer Rejected")
        case .rejected: String(localized: "Rejected")
        case .metadataRejected: String(localized: "Metadata Rejected")
        case .invalidBinary: String(localized: "Invalid Binary")
        case .waitingForExportCompliance: String(localized: "Waiting for Export Compliance")
        case .waitingForReview: String(localized: "Waiting for Review")
        case .inReview: String(localized: "In Review")
        case .accepted: String(localized: "Accepted")
        case .pendingDeveloperRelease: String(localized: "Pending Developer Release")
        case .pendingAppleRelease: String(localized: "Pending Apple Release")
        case .processingForDistribution: String(localized: "Processing for Distribution")
        case .readyForDistribution: String(localized: "Ready for Distribution")
        }
    }

    /// App Store Connect accepts version-level metadata changes only before
    /// the version is submitted (a draft review submission still counts),
    /// or after it's rejected.
    var isEditable: Bool {
        switch self {
        case .prepareForSubmission, .readyForReview, .developerRejected, .rejected, .metadataRejected: true
        case .invalidBinary, .waitingForExportCompliance, .waitingForReview, .inReview, .accepted,
             .pendingDeveloperRelease, .pendingAppleRelease, .processingForDistribution, .readyForDistribution: false
        }
    }

    /// On the App Store now.
    var isLive: Bool { self == .readyForDistribution }
}
