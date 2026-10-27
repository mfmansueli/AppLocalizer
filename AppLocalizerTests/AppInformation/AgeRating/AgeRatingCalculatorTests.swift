//
//  AgeRatingCalculatorTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// The rating preview: Apple's mapping isn't public, so these pin the
/// prototype's table that `AgeRatingCalculator` documents.
@Suite("AgeRatingCalculator")
struct AgeRatingCalculatorTests {
    private func rating(_ answers: [AgeRatingQuestion: AgeRatingAnswer]) -> AgeRating {
        AgeRatingCalculator.rating(for: AgeRatingAnswers(answers))
    }

    @Test func nothingPresentIsFourPlusEverywhere() {
        let preview = AgeRatingCalculator.preview(for: AgeRatingAnswers())
        #expect(preview.calculated == .fourPlus)
        #expect(preview.effective == .fourPlus)
        #expect(preview.australia == "4+")
        #expect(preview.brazil == "L")
        #expect(preview.korea == "All")
    }

    @Test func eachContentAnswerRaisesTheRatingToItsLevel() {
        let table: [(AgeRatingQuestion, AgeRating, AgeRating)] = [
            (.cartoonViolence, .ninePlus, .thirteenPlus),
            (.realisticViolence, .sixteenPlus, .eighteenPlus),
            (.sexualContent, .sixteenPlus, .eighteenPlus),
            (.profanity, .ninePlus, .thirteenPlus),
            (.horror, .ninePlus, .thirteenPlus),
            (.matureThemes, .ninePlus, .sixteenPlus),
            (.substances, .thirteenPlus, .sixteenPlus),
            (.weapons, .ninePlus, .thirteenPlus),
            (.medical, .thirteenPlus, .sixteenPlus),
            (.simulatedGambling, .thirteenPlus, .eighteenPlus),
            (.contests, .fourPlus, .ninePlus),
        ]
        for (question, infrequent, frequent) in table {
            #expect(rating([question: .infrequent]) == infrequent, "\(question) infrequent")
            #expect(rating([question: .frequent]) == frequent, "\(question) frequent")
            #expect(rating([question: .none]) == .fourPlus, "\(question) none")
        }
    }

    @Test func capabilitiesThatChangeTheRating() {
        #expect(rating([.wellness: .affirmative]) == .ninePlus)
        #expect(rating([.lootBoxes: .affirmative]) == .ninePlus)
        #expect(rating([.socialMedia: .affirmative]) == .thirteenPlus)
        #expect(rating([.webAccess: .affirmative]) == .sixteenPlus)
        #expect(rating([.gambling: .affirmative]) == .eighteenPlus)
        for question in [AgeRatingQuestion.messaging, .userGeneratedContent, .advertising, .parentalControls, .ageAssurance] {
            #expect(rating([question: .affirmative]) == .fourPlus, "\(question)")
        }
    }

    @Test func theHighestAnswerWins() {
        #expect(rating([.cartoonViolence: .infrequent, .substances: .frequent, .socialMedia: .affirmative]) == .sixteenPlus)
    }

    @Test func graphicContentAtAnyLevelIsUnrated() {
        #expect(rating([.graphicViolence: .infrequent]) == .unrated)
        #expect(rating([.graphicSexualContent: .frequent, .cartoonViolence: .infrequent]) == .unrated)
        let preview = AgeRatingCalculator.preview(for: AgeRatingAnswers([.graphicViolence: .frequent]))
        #expect(preview.brazil == "—")
        #expect(preview.korea == "—")
    }

    @Test func regionalRatings() {
        let social = AgeRatingCalculator.preview(for: AgeRatingAnswers([.socialMedia: .affirmative]))
        #expect(social.effective == .thirteenPlus)
        #expect(social.australia == "16+")
        #expect(social.brazil == "A14")
        #expect(social.korea == "12+")

        let simulated = AgeRatingCalculator.preview(for: AgeRatingAnswers([.simulatedGambling: .infrequent]))
        #expect(simulated.australia == "R 18+")

        let ugc = AgeRatingCalculator.preview(for: AgeRatingAnswers([.userGeneratedContent: .affirmative]))
        #expect(ugc.brazil == "A6")

        let adult = AgeRatingCalculator.preview(for: AgeRatingAnswers([.gambling: .affirmative]))
        #expect(adult.australia == "18+")
        #expect(adult.brazil == "A18")
        #expect(adult.korea == "19+")
    }

    @Test func anOverrideRaisesTheRatingAndTheRegionsFollowIt() {
        let preview = AgeRatingCalculator.preview(for: AgeRatingAnswers([.wellness: .affirmative]), override: .thirteenPlus)
        #expect(preview.calculated == .ninePlus)
        #expect(preview.effective == .thirteenPlus)
        #expect(preview.brazil == "A14")
        #expect(preview.korea == "12+")
    }

    @Test func anOverrideBelowTheCalculatedRatingChangesNothing() {
        let preview = AgeRatingCalculator.preview(for: AgeRatingAnswers([.webAccess: .affirmative]), override: .thirteenPlus)
        #expect(preview.effective == .sixteenPlus)
    }

    @Test func overridesOfferOnlyHigherRatings() {
        #expect(AgeRating.overrides(above: .fourPlus) == [.ninePlus, .thirteenPlus, .sixteenPlus, .eighteenPlus])
        #expect(AgeRating.overrides(above: .ninePlus) == [.thirteenPlus, .sixteenPlus, .eighteenPlus])
        #expect(AgeRating.overrides(above: .eighteenPlus).isEmpty)
    }
}
