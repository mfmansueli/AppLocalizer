//
//  ExistingLocalizationUpdateTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Which refused `POST`s turn into an update, where the localization is
/// looked up, and which of its texts an update would overwrite.
@Suite("ExistingLocalizationUpdate")
struct ExistingLocalizationUpdateTests {
    private static func create(_ type: String, attributes: [String: String?], parent: String, parentType: String, parentID: String) -> PushRequest {
        let document = StorePageWriteDocument.create(type: type, attributes: attributes, parent: parent, parentType: parentType, parentID: parentID)
        return PushRequest(method: .post, path: "/v1/\(type)", body: document.encoded())
    }

    private static let versionCreate = create(
        "appStoreVersionLocalizations",
        attributes: ["locale": "ja", "description": "日記", "keywords": nil],
        parent: "appStoreVersion", parentType: "appStoreVersions", parentID: "v2"
    )

    @Test func aVersionLocalizationIsLookedUpUnderItsVersion() throws {
        let update = try #require(ExistingLocalizationUpdate(Self.versionCreate))
        #expect(update.locale == "ja")
        #expect(update.lookupPath == "/v1/appStoreVersions/v2/appStoreVersionLocalizations?limit=200")
        #expect(update.attributes == ["description": "日記", "keywords": nil])
    }

    @Test func anAppInfoLocalizationIsLookedUpUnderItsAppInfo() throws {
        let request = Self.create(
            "appInfoLocalizations", attributes: ["locale": "ko", "name": "루멘"], parent: "appInfo", parentType: "appInfos", parentID: "info"
        )
        let update = try #require(ExistingLocalizationUpdate(request))
        #expect(update.lookupPath == "/v1/appInfos/info/appInfoLocalizations?limit=200")
        let patch = try #require(update.update(id: "il-ko"))
        #expect(patch == ListingChangeBuilder.patch(
            path: "/v1/appInfoLocalizations/il-ko", type: "appInfoLocalizations", id: "il-ko", attributes: ["name": "루멘"]
        ))
    }

    @Test func otherRequestsDontTurnIntoUpdates() {
        let patch = ListingChangeBuilder.patch(path: "/v1/appStoreVersionLocalizations/vl", type: "appStoreVersionLocalizations", id: "vl", attributes: [:])
        #expect(ExistingLocalizationUpdate(patch) == nil)
        #expect(ExistingLocalizationUpdate(PushRequest(method: .post, path: "/v1/appScreenshotSets", body: Data("{}".utf8))) == nil)
        #expect(ExistingLocalizationUpdate(PushRequest(method: .post, path: "/v1/subscriptionPrices", body: nil)) == nil)
    }

    @Test func emptyOrMatchingTextsAreNotOverwritten() throws {
        let update = try #require(ExistingLocalizationUpdate(Self.versionCreate))
        let data = Data(#"""
        {"data":[
          {"id":"vl-en","attributes":{"locale":"en-US","description":"Journal"}},
          {"id":"vl-ja","attributes":{"locale":"ja","description":"日記","keywords":""}}
        ]}
        """#.utf8)
        let existing = try #require(update.existing(in: data))
        #expect(existing.id == "vl-ja")
        #expect(existing.overwritten.isEmpty)
    }

    @Test func otherTextAndClearingTextCountAsOverwriting() throws {
        let update = try #require(ExistingLocalizationUpdate(Self.versionCreate))
        let data = Data(#"{"data":[{"id":"vl-ja","attributes":{"locale":"ja","description":"別の説明","keywords":"日記,気分"}}]}"#.utf8)
        #expect(update.existing(in: data)?.overwritten == ["description", "keywords"])
        #expect(update.otherText(in: ["description", "keywords"]).errorDescription
            == "Japanese is already in App Store Connect with its own Description and Keywords, so nothing was overwritten. "
            + "Open the Store Page to review these as edits of what’s there.")
    }

    @Test func aLocaleThatIsntThereIsNotFound() throws {
        let update = try #require(ExistingLocalizationUpdate(Self.versionCreate))
        #expect(update.existing(in: Data(#"{"data":[{"id":"vl-en","attributes":{"locale":"en-US"}}]}"#.utf8)) == nil)
        #expect(update.existing(in: Data("not json".utf8)) == nil)
    }

    @Test func aPageCreatedWithoutTextNeedsNoUpdate() throws {
        let request = Self.create(
            "appStoreVersionLocalizations", attributes: ["locale": "pl"], parent: "appStoreVersion", parentType: "appStoreVersions", parentID: "v2"
        )
        let update = try #require(ExistingLocalizationUpdate(request))
        #expect(update.update(id: "vl-pl") == nil)
    }

    @Test func onlyApplesDuplicateCodeCounts() {
        #expect(AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID.DUPLICATE", detail: nil).isDuplicate)
        #expect(!AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.ATTRIBUTE.INVALID", detail: nil).isDuplicate)
        #expect(!AppStoreConnectError.server(statusCode: 500, detail: nil).isDuplicate)
    }
}
