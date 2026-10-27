//
//  AgeRatingQuestionGroup.swift
//  AppLocalizer
//

import Foundation

/// The questionnaire's three groups, in Apple's order.
enum AgeRatingQuestionGroup: String, CaseIterable, Identifiable, Hashable, Sendable {
    case content
    case capabilities
    case gambling

    var id: String { rawValue }

    var title: String {
        switch self {
        case .content: String(localized: "Content")
        case .capabilities: String(localized: "Capabilities")
        case .gambling: String(localized: "Gambling, contests and loot boxes")
        }
    }

    var questions: [AgeRatingQuestion] {
        AgeRatingQuestion.allCases.filter { $0.group == self }
    }
}
