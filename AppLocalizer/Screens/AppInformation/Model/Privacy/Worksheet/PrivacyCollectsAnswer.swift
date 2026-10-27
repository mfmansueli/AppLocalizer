//
//  PrivacyCollectsAnswer.swift
//  AppLocalizer
//

import Foundation

/// The questionnaire's first question, "Do you or your third-party partners
/// collect data from this app?", with who answered it.
struct PrivacyCollectsAnswer: Hashable, Codable, Sendable {
    var value: Bool
    var status: PrivacyRowStatus
    /// The assistant that suggested it, while the answer is its.
    var client: String?
    var confidence: PrivacyConfidence?

    static func yours(_ value: Bool) -> PrivacyCollectsAnswer {
        PrivacyCollectsAnswer(value: value, status: .yours)
    }

    /// Counts once reviewed; nil while it's an unreviewed suggestion.
    var countedValue: Bool? {
        status.isReviewed ? value : nil
    }

    /// The person picked Yes or No.
    mutating func set(_ newValue: Bool) {
        let wasAssistants = status.isAssistants && client != nil
        if newValue == value, status == .unreviewed {
            status = .accepted
            return
        }
        guard newValue != value else { return }
        value = newValue
        status = wasAssistants ? .edited : .yours
    }
}
