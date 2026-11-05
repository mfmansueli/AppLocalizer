//
//  InAppDraftRefusal.swift
//  AppLocalizer
//

import Foundation

/// App Store Connect wouldn't make a draft version of a group's,
/// subscription's or purchase's texts, e.g. while the newest one is
/// waiting for App Review. Says which version and what to do, with Apple's
/// own words after.
struct InAppDraftRefusal: LocalizedError, Equatable, Sendable {
    /// The newest version's number and state, if the list had one.
    var latestVersion: Int?
    var latestState: String?
    var refusal: AppStoreConnectError

    /// States that keep the texts until App Review is done with them.
    static let inReviewStates: Set<String> = ["READY_FOR_REVIEW", "WAITING_FOR_REVIEW", "IN_REVIEW"]

    var errorDescription: String? {
        let apple = refusal.pushFailureText
        guard let latestState, Self.inReviewStates.contains(latestState) else {
            return String(localized: "App Store Connect didn’t make a new version for these texts: \(apple)")
        }
        let version = latestVersion.map { String(localized: "Version \($0)") } ?? String(localized: "The current version")
        return String(localized: """
        \(version) of these texts is \(Self.title(of: latestState)), so App Store Connect won’t take new ones yet. \
        Push again once App Review is done, or after removing it from review in App Store Connect. (\(apple))
        """)
    }

    /// "Waiting for Review", as App Store Connect names the state.
    static func title(of state: String) -> String {
        switch state {
        case "READY_FOR_REVIEW": String(localized: "in a review submission")
        case "WAITING_FOR_REVIEW": String(localized: "Waiting for Review")
        case "IN_REVIEW": String(localized: "In Review")
        default: state
        }
    }
}
