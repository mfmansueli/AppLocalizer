//
//  PrivacyReviewedAnswers.swift
//  AppLocalizer
//

import Foundation

/// The answers that count: the reviewed first question, and every reviewed
/// type that's collected. It's what the label preview, the checklist and
/// the export show, and what Mark as Published keeps as its snapshot.
struct PrivacyReviewedAnswers: Hashable, Codable, Sendable {
    var collects: Bool?
    var collected: [PrivacyDataType: PrivacyAnswer]

    /// The collected types in App Store Connect's order.
    var collectedTypes: [PrivacyDataType] {
        PrivacyDataType.allCases.filter { collected[$0] != nil }
    }
}
