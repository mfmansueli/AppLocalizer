//
//  PushRequestPlaceholderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// `{createdID}` and `{secret:…}` in a request's path and body, filled in
/// only when it's sent.
@Suite("PushRequest placeholders")
struct PushRequestPlaceholderTests {
    private static let publish = PushRequest(
        method: .patch,
        path: "/v1/accessibilityDeclarations/{createdID}",
        body: Data(#"{"data":{"id":"{createdID}","type":"accessibilityDeclarations","attributes":{"publish":true}}}"#.utf8)
    )

    @Test func theCreatedIDFillsThePathAndTheBody() throws {
        #expect(Self.publish.needsCreatedID)
        let resolved = try Self.publish.resolved(createdID: "d42") { _ in nil }
        #expect(resolved.path == "/v1/accessibilityDeclarations/d42")
        let body = try #require(resolved.body)
        #expect(String(data: body, encoding: .utf8)?.contains(#""id":"d42""#) == true)
    }

    @Test func withoutACreatedIDItThrows() {
        #expect(throws: PushRequestPlaceholderError.missingCreatedID) {
            try Self.publish.resolved(createdID: nil) { _ in nil }
        }
    }

    @Test func aSecretIsReadByNameAndEscapedForJSON() throws {
        let name = "appReview.lumen.password"
        let body = #"{"data":{"attributes":{"demoAccountPassword":"\#(PushRequest.secretPlaceholder(named: name))"}}}"#
        let request = PushRequest(method: .patch, path: "/v1/appStoreReviewDetails/r1", body: Data(body.utf8))
        #expect(request.secretNames == [name])

        let resolved = try request.resolved(createdID: nil) { $0 == name ? #"pa"ss\word"# : nil }
        let sent = try #require(resolved.body)
        let object = try #require(JSONSerialization.jsonObject(with: sent) as? [String: [String: [String: String]]])
        #expect(object["data"]?["attributes"]?["demoAccountPassword"] == #"pa"ss\word"#)
    }

    @Test func aMissingSecretThrowsWithItsName() {
        let body = #"{"password":"\#(PushRequest.secretPlaceholder(named: "gone"))"}"#
        let request = PushRequest(method: .patch, path: "/v1/x", body: Data(body.utf8))
        #expect(throws: PushRequestPlaceholderError.missingSecret("gone")) {
            try request.resolved(createdID: nil) { _ in nil }
        }
    }

    @Test func aRequestWithoutPlaceholdersIsSentAsItIs() throws {
        let request = PushRequest(method: .post, path: "/v1/subscriptionPrices", body: Data(#"{"a":"{b}"}"#.utf8))
        #expect(try request.resolved(createdID: nil) { _ in nil } == request)
        #expect(request.secretNames.isEmpty)
        #expect(!request.needsCreatedID)
    }
}
