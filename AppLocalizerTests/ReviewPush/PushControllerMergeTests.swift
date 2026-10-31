//
//  PushControllerMergeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// An age rating declaration's answers go to App Store Connect in one
/// `PATCH`: Apple refuses a partial one while the questionnaire isn't fully
/// answered ("You must provide a value for the attribute 'ageAssurance'").
@MainActor
@Suite("PushController · merged writes")
struct PushControllerMergeTests {
    private typealias Support = AppInformationTestSupport
    private let queue = ChangeQueue()
    private let history = PushHistory()

    private static let declaration = "/v1/ageRatingDeclarations/age-1"
    private static let check = "/v1/appInfos/info-1/ageRatingDeclaration"
    /// The declaration as fetched: profanity None, nothing else answered.
    private let values = AgeRatingValues(
        answers: AgeRatingAnswers([.profanity: .none]),
        apiValues: ["profanityOrCrudeHumor": .string("NONE"), "socialMedia": .null, "healthOrWellnessTopics": .null]
    )

    private func controller(_ transport: FakePushTransport) -> PushController {
        let controller = PushController(queue: queue, history: history, transport: transport)
        controller.appName = { "App \($0)" }
        return controller
    }

    private func remote(profanity: String = "NONE") -> [String: Data] {
        let json = #"{"data":{"attributes":{"profanityOrCrudeHumor":"\#(profanity)","socialMedia":null,"healthOrWellnessTopics":null}}}"#
        return [Self.check: Data(json.utf8)]
    }

    /// Three answers with a Store Page change between them.
    private func queueAnswers() throws {
        try queue.upsert(contentsOf: [
            #require(Support.builder.ageAnswerChange(.profanity, from: values, to: .infrequent)),
            PushFixtures.listing("Subtitle", app: Support.appID),
            #require(Support.builder.ageAnswerChange(.socialMedia, from: values, to: .negative)),
            #require(Support.builder.ageAnswerChange(.wellness, from: values, to: .affirmative)),
        ])
    }

    @Test func theAnswersGoOutInOnePatchWhereTheFirstWas() async throws {
        let transport = FakePushTransport(remote: remote())
        let push = controller(transport)
        try queueAnswers()

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == [Self.declaration, "/v1/appStoreVersionLocalizations/de-Subtitle"])
        let attributes = Support.attributes(transport.sent.first)
        #expect(attributes["profanityOrCrudeHumor"] as? String == "INFREQUENT")
        #expect(attributes["socialMedia"] as? Bool == false)
        #expect(attributes["healthOrWellnessTopics"] as? Bool == true)
        #expect(transport.fetched == [Self.check], "One GET checks every answer.")
        #expect(push.doneCount == 4)
        #expect(push.title == "4 pushed")
        #expect(queue.changes.isEmpty)
        #expect(history.lastRecord(for: Support.appID)?.pushed.count == 4)
    }

    @Test func applesRefusalFailsEveryAnswerAndRetrySendsThemTogetherAgain() async throws {
        let refusal = AppStoreConnectError.rejected(
            statusCode: 409,
            code: "ENTITY_ERROR.ATTRIBUTE.REQUIRED",
            detail: "You must provide a value for the attribute 'ageAssurance' with this request"
        )
        let transport = FakePushTransport(failures: ["ageRatingDeclarations": refusal], remote: remote())
        let push = controller(transport)
        try queueAnswers()

        push.push(queue.changes)
        await push.waitUntilFinished()

        let text = "ENTITY_ERROR.ATTRIBUTE.REQUIRED — You must provide a value for the attribute 'ageAssurance' with this request"
        #expect(push.failedCount == 3)
        #expect(push.items.filter { $0.change.section == .appInformation }.allSatisfy { $0.status == .failed(text) })
        #expect(push.title == "1 pushed · 3 failed")
        #expect(queue.changes.count == 3)
        #expect(history.lastRecord(for: Support.appID)?.failures.count == 3)

        push.retryFailed()
        await push.waitUntilFinished()
        #expect(transport.sent.map(\.path) == [Self.declaration, "/v1/appStoreVersionLocalizations/de-Subtitle", Self.declaration])
    }

    @Test func anAnswerChangedInAppStoreConnectStaysForReview() async throws {
        let transport = FakePushTransport(remote: remote(profanity: "FREQUENT"))
        let push = controller(transport)
        try queueAnswers()

        push.push(queue.changes)
        await push.waitUntilFinished()

        let profanityID = Support.builder.changeID(.ageRating, AgeRatingQuestion.profanity.rawValue)
        #expect(push.items.first { $0.id == profanityID }?.status == .conflict)
        #expect(queue.change(id: profanityID)?.remoteConflict?.remoteRawValue == "FREQUENT")
        let attributes = Support.attributes(transport.sent.first)
        #expect(attributes["profanityOrCrudeHumor"] == nil)
        #expect(attributes.count == 2)
        #expect(push.doneCount == 3)
    }

    @Test func aSingleAnswerIsSentAsItWas() async throws {
        let transport = FakePushTransport(remote: remote())
        let push = controller(transport)
        try queue.upsert(#require(Support.builder.ageAnswerChange(.profanity, from: values, to: .frequent)))

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == [Self.declaration])
        #expect(Support.attributes(transport.sent.first).count == 1)
        #expect(push.doneCount == 1)
    }
}
