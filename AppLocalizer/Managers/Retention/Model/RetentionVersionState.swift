//
//  RetentionVersionState.swift
//  AppLocalizer
//

import Foundation

/// A `retentionMessageVersions` resource's `state` (App Store Connect API
/// 4.6). A version can't be changed once it's approved: new text goes into a
/// new version, which App Review checks again.
enum RetentionVersionState: String, CaseIterable, Hashable, Codable, Sendable {
    case prepareForSubmission = "PREPARE_FOR_SUBMISSION"
    case readyForReview = "READY_FOR_REVIEW"
    case waitingForReview = "WAITING_FOR_REVIEW"
    case inReview = "IN_REVIEW"
    case developerRejected = "DEVELOPER_REJECTED"
    case rejected = "REJECTED"
    case accepted = "ACCEPTED"
    case approved = "APPROVED"

    /// The pill: In Review, Live (approved), Rejected, else Draft.
    var status: RetentionMessageStatus {
        switch self {
        case .waitingForReview, .inReview: .inReview
        case .accepted, .approved: .live
        case .rejected: .rejected
        case .prepareForSubmission, .readyForReview, .developerRejected: .draft
        }
    }

    /// Its localizations still take changes, so a push writes into it
    /// instead of making a new version. Untested against Apple for
    /// `READY_FOR_REVIEW` and `REJECTED`.
    var takesEdits: Bool {
        switch self {
        case .prepareForSubmission, .readyForReview, .developerRejected, .rejected: true
        case .waitingForReview, .inReview, .accepted, .approved: false
        }
    }

    /// Apple has it; a change waits until the review ends.
    var isWithApple: Bool {
        self == .waitingForReview || self == .inReview
    }

    /// Subscribers see it.
    var isLive: Bool {
        self == .accepted || self == .approved
    }

    /// Of several versions, the one AppLocalizer edits: one still in the
    /// works or with Apple comes before the live one.
    var priority: Int {
        switch self {
        case .prepareForSubmission, .readyForReview, .developerRejected, .rejected: 3
        case .waitingForReview, .inReview: 2
        case .accepted, .approved: 1
        }
    }
}
