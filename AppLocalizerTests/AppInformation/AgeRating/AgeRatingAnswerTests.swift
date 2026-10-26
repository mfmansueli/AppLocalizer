//
//  AgeRatingAnswerTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// Reading and writing `ageRatingDeclarations` values: content levels as
/// strings, capabilities as booleans, the older level names, and ratings.
@Suite("Age rating values")
struct AgeRatingAnswerTests {
    @Test func answersRoundTripThroughTheirAPIValues() {
        for answer in [AgeRatingAnswer.none, .infrequent, .frequent, .negative, .affirmative] {
            #expect(AgeRatingAnswer(apiValue: answer.apiValue) == answer)
        }
        #expect(AgeRatingAnswer(apiValue: .string("INFREQUENT_OR_MILD")) == .infrequent)
        #expect(AgeRatingAnswer(apiValue: .string("FREQUENT_OR_INTENSE")) == .frequent)
        #expect(AgeRatingAnswer(apiValue: .null) == nil)
    }

    @Test func aDeclarationReadsOnlyAnswersItsQuestionOffers() {
        let answers = AgeRatingAnswers(attributes: [
            "violenceCartoonOrFantasy": .string("FREQUENT"),
            "socialMedia": .bool(true),
            "profanityOrCrudeHumor": .bool(true),
            "messagingAndChat": .string("FREQUENT"),
            "somethingNew": .string("FREQUENT"),
        ])
        #expect(answers[.cartoonViolence] == .frequent)
        #expect(answers[.socialMedia] == .affirmative)
        #expect(answers[.profanity] == .none)
        #expect(answers[.messaging] == .negative)
    }

    @Test func eachQuestionHasItsAPIKeyAndADefault() {
        #expect(Set(AgeRatingQuestion.allCases.map(\.apiKey)).count == AgeRatingQuestion.allCases.count)
        for question in AgeRatingQuestion.allCases {
            #expect(question.answers.contains(question.defaultAnswer))
            #expect(AgeRatingQuestion.question(apiKey: question.apiKey) == question)
        }
    }

    @Test func ratingsReadTheNewAndTheOlderScale() {
        #expect(AgeRating(apiValue: "NINE_PLUS") == .ninePlus)
        #expect(AgeRating(apiValue: "TWELVE_PLUS") == nil)
        #expect(AgeRating.title(forAPIValue: "SIXTEEN_PLUS") == "16+")
        #expect(AgeRating.title(forAPIValue: "TWELVE_PLUS") == "12+")
        #expect(AgeRating.title(forAPIValue: "SEVENTEEN_PLUS") == "17+")
        #expect(AgeRating.title(forAPIValue: nil) == nil)
    }

    @Test func anUnansweredQuestionIsNullInTheDeclaration() {
        let values = AgeRatingValues(apiValues: ["socialMedia": .null, "advertising": .bool(false)])
        #expect(!values.isAnswered(.socialMedia))
        #expect(values.isAnswered(.advertising))
        #expect(!values.isAnswered(.gambling))
    }
}
