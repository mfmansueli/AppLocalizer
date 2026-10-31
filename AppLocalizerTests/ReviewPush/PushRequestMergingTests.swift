//
//  PushRequestMergingTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Which writes go out together (an age rating declaration's `PATCH`es),
/// and how their documents combine.
@Suite("PushRequest merging")
struct PushRequestMergingTests {
    private typealias Support = AppInformationTestSupport

    @Test func anAgeRatingDeclarationsPatchesShareTheirPath() {
        let patch = PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-1")
        #expect(patch.mergeKey == "/v1/ageRatingDeclarations/age-1")
    }

    @Test(arguments: [
        PushRequest(method: .post, path: "/v1/ageRatingDeclarations/age-1"),
        PushRequest(method: .patch, path: "/v1/appStoreReviewDetails/review-1"),
        PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-1/relationships/appInfo"),
    ])
    func everythingElseGoesOnItsOwn(request: PushRequest) {
        #expect(request.mergeKey == nil)
    }

    @Test func answersMergeIntoOneDocument() throws {
        let values = AgeRatingValues()
        let profanity = try #require(Support.builder.ageAnswerChange(.profanity, from: values, to: .infrequent))
        let socialMedia = try #require(Support.builder.ageAnswerChange(.socialMedia, from: values, to: .affirmative))
        let override = try #require(Support.builder.overrideChange(from: values, to: .thirteenPlus, reason: "Mature themes"))

        let merged = try #require(PushRequest.merged([profanity, socialMedia, override].map { $0.requests[0] }))

        #expect(merged.method == .patch)
        #expect(merged.path == "/v1/ageRatingDeclarations/age-1")
        let data = Support.json(merged)["data"] as? [String: Any]
        #expect(data?["type"] as? String == "ageRatingDeclarations")
        #expect(data?["id"] as? String == "age-1")
        let attributes = Support.attributes(merged)
        #expect(attributes.count == 3)
        #expect(attributes["profanityOrCrudeHumor"] as? String == "INFREQUENT")
        #expect(attributes["socialMedia"] as? Bool == true)
        #expect(attributes["ageRatingOverrideV2"] as? String == "THIRTEEN_PLUS")
    }

    @Test func aLaterAnswerForTheSameQuestionWins() throws {
        let values = AgeRatingValues()
        let first = try #require(Support.builder.ageAnswerChange(.horror, from: values, to: .infrequent))
        let second = try #require(Support.builder.ageAnswerChange(.horror, from: values, to: .frequent))
        let merged = try #require(PushRequest.merged([first.requests[0], second.requests[0]]))
        #expect(Support.attributes(merged)["horrorOrFearThemes"] as? String == "FREQUENT")
    }

    @Test func differentResourcesOrBodiesDontMerge() {
        let body = Data(#"{"data":{"type":"ageRatingDeclarations","id":"age-1","attributes":{"lootBox":false}}}"#.utf8)
        let other = Data(#"{"data":{"type":"ageRatingDeclarations","id":"age-2","attributes":{"lootBox":true}}}"#.utf8)
        let one = PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-1", body: body)
        #expect(PushRequest.merged([one, PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-2", body: other)]) == nil)
        #expect(PushRequest.merged([one, PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-1", body: other)]) == nil)
        #expect(PushRequest.merged([one, PushRequest(method: .patch, path: "/v1/ageRatingDeclarations/age-1")]) == nil)
        #expect(PushRequest.merged([]) == nil)
    }
}
