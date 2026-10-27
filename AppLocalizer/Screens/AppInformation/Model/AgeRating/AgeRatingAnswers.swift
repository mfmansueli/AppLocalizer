//
//  AgeRatingAnswers.swift
//  AppLocalizer
//

import Foundation

/// A whole questionnaire's answers. A question that hasn't been answered
/// reads as its default (None or No).
struct AgeRatingAnswers: Hashable, Sendable {
    private var values: [AgeRatingQuestion: AgeRatingAnswer]

    init(_ values: [AgeRatingQuestion: AgeRatingAnswer] = [:]) {
        self.values = values
    }

    /// Reads an `ageRatingDeclarations` response's attributes.
    init(attributes: [String: AppInformationAPIValue]) {
        var values: [AgeRatingQuestion: AgeRatingAnswer] = [:]
        for (key, value) in attributes {
            guard let question = AgeRatingQuestion.question(apiKey: key), let answer = AgeRatingAnswer(apiValue: value),
                  question.answers.contains(answer)
            else { continue }
            values[question] = answer
        }
        self.values = values
    }

    subscript(question: AgeRatingQuestion) -> AgeRatingAnswer {
        get { values[question] ?? question.defaultAnswer }
        set { values[question] = question.answers.contains(newValue) ? newValue : question.defaultAnswer }
    }
}
