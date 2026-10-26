//
//  AgeRatingValues.swift
//  AppLocalizer
//

import Foundation

/// The Age Rating page's values: the questionnaire and the override.
struct AgeRatingValues: Hashable, Sendable {
    var answers = AgeRatingAnswers()
    /// "Rate higher than calculated"; nil when off.
    var override: AgeRating?
    /// The rating App Store Connect shows now (`appStoreAgeRating`), e.g.
    /// "4+"; nil before the questionnaire was ever answered.
    var currentRating: String?
    /// The declaration's attributes as App Store Connect sent them, for
    /// conflict checks: an unanswered boolean is `null`, not false.
    var apiValues: [String: AppInformationAPIValue] = [:]

    /// Whether App Store Connect has an answer for it (an unanswered
    /// question reads as None or No).
    func isAnswered(_ question: AgeRatingQuestion) -> Bool {
        if case .null = apiValues[question.apiKey] ?? .null { return false }
        return true
    }

    var preview: AgeRatingPreview {
        AgeRatingCalculator.preview(for: answers, override: override)
    }
}
