//
//  AppInformationSummary.swift
//  AppLocalizer
//

import Foundation

/// What the overview's App Information card shows for one app. Produced by
/// `AppInformationServices`.
struct AppInformationSummary: Hashable, Sendable {
    /// The App Privacy checklist's state. The API can't write App Privacy, so
    /// it's tracked on this Mac.
    enum PrivacyStatus: String, Hashable, Sendable {
        case notStarted
        case draft
        case confirmed
        case entered
        case outOfDate

        var title: String {
            switch self {
            case .notStarted: String(localized: "Not started")
            case .draft: String(localized: "Draft")
            case .confirmed: String(localized: "Confirmed")
            case .entered: String(localized: "Entered")
            case .outOfDate: String(localized: "Out of date")
            }
        }

        /// Not started and out of date need attention.
        var needsAttention: Bool { self == .notStarted || self == .outOfDate }
    }

    /// e.g. "4+", "9+"; nil when no questionnaire has been answered.
    var ageRating: String?
    var privacyStatus: PrivacyStatus
    /// Contact and notes are filled in.
    var isAppReviewComplete: Bool
}
