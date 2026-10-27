//
//  PrivacyFastlaneCoderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// fastlane's `app_privacy_details.json`: what Export… writes, what Import
/// reads, and the files it can't.
@Suite("PrivacyFastlaneCoder")
struct PrivacyFastlaneCoderTests {
    private typealias Support = PrivacyTestSupport

    @Test func writesFastlanesKeysAndReadsThemBack() throws {
        let answers = PrivacyReviewedAnswers(collects: true, collected: [
            .userId: Support.collected(linked: true),
            .deviceId: Support.collected([.thirdPartyAdvertising, .analytics], linked: true, tracking: true),
            .crash: Support.collected(),
        ])
        let data = try PrivacyFastlaneCoder.encode(answers)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        #expect(json.map { $0["category"] as? String } == ["USER_ID", "DEVICE_ID", "CRASH_DATA"])
        #expect(json[0]["data_protections"] as? [String] == ["DATA_LINKED_TO_YOU"])
        #expect(json[1]["data_protections"] as? [String] == ["DATA_USED_TO_TRACK_YOU", "DATA_LINKED_TO_YOU"])
        #expect(json[1]["purposes"] as? [String] == ["THIRD_PARTY_ADVERTISING", "ANALYTICS"])
        #expect(json[2]["data_protections"] as? [String] == ["DATA_NOT_LINKED_TO_YOU"])

        let imported = try PrivacyFastlaneCoder.decode(data)
        #expect(imported.collects)
        #expect(imported.answers == answers.collected)
        #expect(imported.types == [.userId, .deviceId, .crash])
    }

    @Test func noDataIsDataNotCollected() throws {
        let data = try PrivacyFastlaneCoder.encode(PrivacyReviewedAnswers(collects: false, collected: [:]))
        #expect(String(bytes: data, encoding: .utf8)?.contains("DATA_NOT_COLLECTED") == true)
        let imported = try PrivacyFastlaneCoder.decode(data)
        #expect(!imported.collects)
        #expect(imported.answers.isEmpty)
    }

    @Test func unknownCategoriesAreSetAside() throws {
        let json = #"""
        [{"category":"FINGERPRINT","purposes":["ANALYTICS"],"data_protections":["DATA_LINKED_TO_YOU"]},
         {"category":"EMAIL_ADDRESS","purposes":["APP_FUNCTIONALITY"],"data_protections":["DATA_LINKED_TO_YOU"]}]
        """#
        let imported = try PrivacyFastlaneCoder.decode(Data(json.utf8))
        #expect(imported.unknownCategories == ["FINGERPRINT"])
        #expect(imported.types == [.email])
    }

    @Test func otherFilesAreRefused() {
        #expect(throws: PrivacyFastlaneCoder.Failure.notFastlane) {
            try PrivacyFastlaneCoder.decode(Data(#"{"name":"Lumen"}"#.utf8))
        }
        #expect(throws: PrivacyFastlaneCoder.Failure.empty) {
            try PrivacyFastlaneCoder.decode(Data("[]".utf8))
        }
    }

    @Test func importingMakesTheAnswersThePersonsAndKeepsDifferentSuggestionsAsConflicts() throws {
        var worksheet = Support.proposed([(.email, Support.suggestion(.notCollected, confidence: .low))])
        let file = try PrivacyFastlaneCoder.encode(PrivacyReviewedAnswers(collects: true, collected: [.email: Support.collected(linked: true)]))
        try worksheet.importAnswers(PrivacyFastlaneCoder.decode(file))
        #expect(worksheet.collects?.status == .yours)
        #expect(worksheet[.email]?.status == .yours)
        #expect(worksheet[.email]?.conflict?.answer == .notCollected)
        #expect(worksheet.reviewedAnswers.collectedTypes == [.email])
    }
}
