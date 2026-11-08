//
//  RetentionRulesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Apple's rules for retention messages: 66 and 144 characters, 10
/// messages an app, names that can't repeat, and what each version state
/// lets a push do.
@MainActor
@Suite("Retention rules")
struct RetentionRulesTests {
    @Test func theCountersCountCharactersAsPeopleSeeThem() {
        let text = RetentionText(header: "Café 👩‍👩‍👧", body: String(repeating: "あ", count: 144))
        #expect(text.headerCount == 6)
        #expect(text.bodyCount == 144)
        #expect(!text.isTooLong)
    }

    @Test func oneCharacterOverEitherLimitIsTooLong() {
        #expect(RetentionText(header: String(repeating: "a", count: 67), body: "b").isHeaderTooLong)
        #expect(RetentionText(header: "a", body: String(repeating: "b", count: 145)).isBodyTooLong)
        #expect(!RetentionText(header: String(repeating: "a", count: 66), body: String(repeating: "b", count: 144)).isTooLong)
    }

    @Test func aTextNeedsBothFieldsToBeComplete() {
        #expect(!RetentionText(header: "Stay", body: "  ").isComplete)
        #expect(RetentionText(header: "Stay", body: "Please").isComplete)
        #expect(RetentionText(header: " ", body: "\n").isEmpty)
    }

    @Test func theSampleGermanOfferRunsOver144() throws {
        let german = try #require(RetentionSampleData.offer["de-DE"])
        #expect(RetentionLimits.length(of: german.1) == 149)
        #expect(RetentionLimits.length(of: RetentionSampleData.shorterGerman) <= RetentionLimits.bodyLength)
    }

    @Test(arguments: [
        (RetentionVersionState.prepareForSubmission, RetentionMessageStatus.draft, true),
        (.readyForReview, .draft, true),
        (.waitingForReview, .inReview, false),
        (.inReview, .inReview, false),
        (.rejected, .rejected, true),
        (.approved, .live, false),
    ])
    func versionStatesMapToThePillAndEdits(state: RetentionVersionState, status: RetentionMessageStatus, takesEdits: Bool) {
        #expect(state.status == status)
        #expect(state.takesEdits == takesEdits)
    }

    @Test func aDraftOverALiveVersionIsLive() throws {
        var remote = try #require(RetentionTestFixtures.live().remote)
        remote.versionState = .prepareForSubmission
        #expect(remote.status == .live)
        remote.hasLiveVersion = false
        #expect(remote.status == .draft)
    }

    @Test func anEleventhMessageIsRefused() {
        let existing = (1...10).map { RetentionTestFixtures.englishDraft(id: "draft-\($0)", name: "Message \($0)") }
        let eleventh = RetentionTestFixtures.englishDraft(id: "draft-11", name: "Message 11")
        let builder = RetentionTestFixtures.builder(messages: existing + [eleventh])
        #expect(builder.problems(for: eleventh, messageCount: 11).contains(.tooManyMessages))
        #expect(!builder.problems(for: existing[0], messageCount: 10).contains(.tooManyMessages))
    }

    @Test func aNameCanOnlyBeUsedOnce() {
        let live = RetentionTestFixtures.live()
        let copy = RetentionTestFixtures.englishDraft(name: " Before you go ")
        let builder = RetentionTestFixtures.builder(messages: [live, copy])
        #expect(builder.problems(for: copy, messageCount: 2).first == .nameTaken)
    }

    @Test func whatANewMessageNeeds() {
        var message = RetentionMessage(id: "draft-1", referenceName: "")
        let builder = RetentionTestFixtures.builder(messages: [message])
        #expect(builder.problems(for: message, messageCount: 1) == [.noName, .noSubscriptions, .noSourceText(language: "English (U.S.)")])

        message = RetentionTestFixtures.englishDraft()
        message.kind = .image
        #expect(builder.problems(for: message, messageCount: 1) == [.noImage])
        message.kind = .offer
        #expect(builder.problems(for: message, messageCount: 1) == [.noOffers])
        message.kind = .message
        message.texts["de-DE"] = RetentionText(header: "Bleib", body: String(repeating: "x", count: 150))
        #expect(builder.problems(for: message, messageCount: 1) == [.tooLong(languages: ["German"])])
    }

    @Test func aMessageInReviewWaits() {
        var message = RetentionTestFixtures.live(state: .waitingForReview)
        message.texts["en-US"]?.body = "Your entries stay."
        let builder = RetentionTestFixtures.builder(messages: [message])
        #expect(builder.problems(for: message, messageCount: 1).contains(.withApple))
    }

    @Test func aLiveMessageAsAppStoreConnectHasItHasNoChanges() {
        var message = RetentionTestFixtures.live()
        #expect(!message.hasChanges)
        message.subscriptionIDs = [RetentionTestFixtures.monthly.id]
        #expect(message.hasChanges)
        message = RetentionTestFixtures.live()
        message.texts["fr-FR"]?.header = "Tout reste à vous"
        #expect(message.hasChanges)
    }

    @Test func draftIDsSkipTheOnesTaken() {
        let messages = [RetentionTestFixtures.englishDraft(id: "draft-1"), RetentionTestFixtures.englishDraft(id: "draft-3")]
        #expect(RetentionMessage.draftID(notIn: messages) == "draft-2")
    }

    @Test func eighteenLanguagesWithEnglishFirst() {
        #expect(RetentionLanguages.standard.count == 18)
        #expect(RetentionLanguages.standard.first == .englishUS)
        let sorted = RetentionLanguages.languages(codes: ["ja", "en-US", "de-DE", "fi"], source: .englishUS).map(\.code)
        #expect(sorted == ["en-US", "de-DE", "ja", "fi"])
    }
}
#endif
