//
//  PrivacyPublication.swift
//  AppLocalizer
//

import Foundation

/// "Mark as Published in App Store Connect": when the person said they
/// entered and published the answers there, and a copy of the reviewed
/// answers at that moment, so a later edit or scan can say App Store
/// Connect may no longer match.
struct PrivacyPublication: Hashable, Codable, Sendable {
    var date: Date
    var snapshot: PrivacyReviewedAnswers
}
