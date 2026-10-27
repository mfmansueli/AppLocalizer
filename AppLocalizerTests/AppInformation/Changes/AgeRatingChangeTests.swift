//
//  AgeRatingChangeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Age Rating's changes: one `PATCH` of the declaration per question, an
/// assistant's answer blocked until confirmed, and the override.
@Suite("App Information changes · Age Rating")
struct AgeRatingChangeTests {
    private typealias Support = AppInformationTestSupport
    private let builder = Support.builder

    private let values = AgeRatingValues(
        answers: AgeRatingAnswers([.profanity: .none]),
        currentRating: "4+",
        apiValues: ["profanityOrCrudeHumor": .string("NONE"), "socialMedia": .bool(false), "healthOrWellnessTopics": .null]
    )

    @Test func eachAnswerPatchesTheDeclaration() throws {
        let change = try #require(builder.ageAnswerChange(.profanity, from: values, to: .infrequent))
        #expect(change.id == "appInformation.\(Support.appID).ageRating.profanity")
        #expect(change.oldValue == "None")
        #expect(change.newValue == "Infrequent")
        #expect(change.requests.first?.path == "/v1/ageRatingDeclarations/age-1")
        #expect(Support.attributes(change.requests.first)["profanityOrCrudeHumor"] as? String == "INFREQUENT")
        #expect(Support.attributes(change.restoreRequests.first)["profanityOrCrudeHumor"] as? String == "NONE")
        #expect(change.conflictCheck?.path == "/v1/appInfos/info-1/ageRatingDeclaration")
        #expect(change.conflictCheck?.expected == "NONE")
        #expect(builder.ageAnswerChange(.profanity, from: values, to: .none) == nil)
    }

    @Test func capabilitiesAreBooleans() throws {
        let change = try #require(builder.ageAnswerChange(.socialMedia, from: values, to: .affirmative))
        #expect(Support.attributes(change.requests.first)["socialMedia"] as? Bool == true)
        #expect(change.conflictCheck?.expected == "0")
    }

    @Test func anUnansweredQuestionCanBeAnsweredWithItsDefault() throws {
        let change = try #require(builder.ageAnswerChange(.wellness, from: values, to: .negative))
        #expect(change.oldValue == "Not answered")
        #expect(Support.attributes(change.restoreRequests.first)["healthOrWellnessTopics"] is NSNull)
        #expect(Support.attributes(change.requests.first)["healthOrWellnessTopics"] as? Bool == false)
    }

    @Test func anAssistantsAnswerWaitsForConfirmation() throws {
        let source = ChangeSource.assistant(client: "Claude Code")
        let open = try #require(builder.ageAnswerChange(.socialMedia, from: values, to: .affirmative, source: source, confirmed: false))
        #expect(open.blockedReason != nil)
        #expect(open.source == source)
        let confirmed = try #require(builder.ageAnswerChange(.socialMedia, from: values, to: .affirmative, source: source, confirmed: true))
        #expect(confirmed.blockedReason == nil)

        let answers = builder.assistantAnswers(in: [open])
        #expect(answers[.socialMedia]?.client == "Claude Code")
        #expect(answers[.socialMedia]?.confirmed == false)
        #expect(builder.assistantAnswers(in: [confirmed])[.socialMedia]?.confirmed == true)
    }

    @Test func theOverrideNeedsAReasonAndSendsTheRating() throws {
        let change = try #require(builder.overrideChange(from: values, to: .thirteenPlus, reason: "Reflections can touch on grief."))
        #expect(change.blockedReason == nil)
        #expect(change.newValue.contains("13+"))
        #expect(change.newValue.contains("Reflections can touch on grief."))
        #expect(Support.attributes(change.requests.first)["ageRatingOverrideV2"] as? String == "THIRTEEN_PLUS")
        #expect(builder.overrideChange(from: values, to: .thirteenPlus, reason: " ")?.blockedReason != nil)
        #expect(builder.overrideChange(from: values, to: nil, reason: "") == nil)
    }

    @Test func queuedAnswersAndTheOverrideAreReadBack() throws {
        let changes = try [
            #require(builder.ageAnswerChange(.socialMedia, from: values, to: .affirmative)),
            #require(builder.overrideChange(from: values, to: .sixteenPlus, reason: "Because.")),
        ]
        let shown = builder.ageRating(values, with: changes)
        #expect(shown.answers[.socialMedia] == .affirmative)
        #expect(shown.override == .sixteenPlus)
        #expect(shown.preview.calculated == .thirteenPlus)
        #expect(shown.preview.effective == .sixteenPlus)
    }
}
