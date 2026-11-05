//
//  PushControllerLegacyInAppTextsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// In-App Texts changes queued as pre-4.4.1 `/v1` writes, which App Store
/// Connect refuses as `UNMODIFIABLE`: the push sends the same texts into a
/// version, and says plainly when App Store Connect won't make one because
/// the texts are waiting for App Review.
@MainActor
@Suite("PushController · legacy In-App Texts")
struct PushControllerLegacyInAppTextsTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()

    private static let unmodifiable = AppStoreConnectError.rejected(
        statusCode: 409,
        code: "ENTITY_ERROR.ATTRIBUTE.INVALID.UNMODIFIABLE",
        detail: "The field (NAME) can not be modified"
    )
    private static let groupVersions = "/v1/subscriptionGroups/grp1/versions?limit=200"
    /// Alba's group: version 1 submitted to App Review.
    private static let waiting = Data(#"{"data":[{"id":"gv1","attributes":{"version":1,"state":"WAITING_FOR_REVIEW"}}]}"#.utf8)

    /// A group name for a new locale, queued the pre-4.4.1 way.
    private static func newGroupName(_ locale: String) -> PendingChange {
        let document = StorePageWriteDocument.create(
            type: "subscriptionGroupLocalizations",
            attributes: ["locale": locale, "name": "Alba Premium"],
            parent: "subscriptionGroup",
            parentType: "subscriptionGroups",
            parentID: "grp1"
        )
        return PendingChange(
            id: "storePage.app1.inApp.group.grp1.\(locale).new",
            appID: "app1",
            section: .storePage,
            group: "Store Page · In-App Texts",
            title: "\(locale) · Group name",
            oldValue: "",
            newValue: "Alba Premium",
            requests: [PushRequest(method: .post, path: "/v1/subscriptionGroupLocalizations", body: document.encoded())]
        )
    }

    private func push(_ changes: [PendingChange], via transport: FakePushTransport) async -> PushController {
        let controller = PushController(queue: queue, history: history, transport: transport)
        queue.upsert(contentsOf: changes)
        controller.push(queue.changes)
        await controller.waitUntilFinished()
        return controller
    }

    private func relationshipID(_ request: PushRequest, _ name: String) -> String? {
        StorePageWriteDocument.decode(request.body)?.data.relationships?[name]?.data.id
    }

    @Test func aRefusedLegacyPostGoesIntoANewDraft() async {
        let transport = FakePushTransport(
            createFailures: ["/v1/subscriptionGroupLocalizations": Self.unmodifiable],
            remote: [
                Self.groupVersions: Self.waiting,
                "/v1/subscriptionGroupVersions/gv2/localizations?limit=200": Data(#"{"data":[{"id":"gl1","attributes":{"locale":"en-US"}}]}"#.utf8),
            ],
            responses: [
                "/v1/subscriptionGroupVersions": Data(#"{"data":{"type":"subscriptionGroupVersions","id":"gv2"}}"#.utf8),
                "/v2/subscriptionGroupLocalizations": Data(#"{"data":{"type":"subscriptionGroupLocalizations","id":"gl2"}}"#.utf8),
            ]
        )
        let controller = await push([Self.newGroupName("de-DE"), Self.newGroupName("fr-CA")], via: transport)

        #expect(controller.doneCount == 2)
        #expect(queue.changes.isEmpty)
        // One draft for both locales, each locale posted into it.
        #expect(transport.sent.map { "\($0.method.rawValue) \($0.path)" } == [
            "POST /v1/subscriptionGroupLocalizations",
            "POST /v1/subscriptionGroupVersions",
            "POST /v2/subscriptionGroupLocalizations",
            "POST /v1/subscriptionGroupLocalizations",
            "POST /v2/subscriptionGroupLocalizations",
        ])
        let posts = transport.sent.filter { $0.path == "/v2/subscriptionGroupLocalizations" }
        #expect(posts.map { relationshipID($0, "version") } == ["gv2", "gv2"])
        #expect(posts.map { StorePageWriteDocument.decode($0.body)?.attribute("locale") } == ["de-DE", "fr-CA"])
    }

    @Test func noDraftWhileWaitingForReviewSaysSo() async {
        let stateError = AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR", detail: "A version is already in review.")
        let transport = FakePushTransport(
            createFailures: ["/v1/subscriptionGroupLocalizations": Self.unmodifiable, "/v1/subscriptionGroupVersions": stateError],
            remote: [Self.groupVersions: Self.waiting]
        )
        let controller = await push([Self.newGroupName("de-DE"), Self.newGroupName("fr-CA")], via: transport)

        #expect(controller.failedCount == 2)
        #expect(queue.changes.count == 2)
        for item in controller.items {
            guard case let .failed(text) = item.status else { Issue.record("Expected a failure, got \(item.status)"); continue }
            #expect(text.hasPrefix("Version 1 of these texts is Waiting for Review"))
            #expect(text.contains("STATE_ERROR"))
        }
        // The second locale isn't asked for a draft again in the same push.
        #expect(transport.sent.count { $0.path == "/v1/subscriptionGroupVersions" } == 1)
    }

    @Test func aRefusedLegacyPatchFindsItsOwnerAndLocale() async throws {
        let document = StorePageWriteDocument.update(type: "subscriptionGroupLocalizations", id: "gl1", attributes: ["name": "Alba Plus"])
        let change = PendingChange(
            id: "storePage.app1.inApp.group.grp1.de-DE.name",
            appID: "app1",
            section: .storePage,
            group: "Store Page · In-App Texts",
            title: "German · Group name",
            oldValue: "Alba Premium",
            newValue: "Alba Plus",
            requests: [PushRequest(method: .patch, path: "/v1/subscriptionGroupLocalizations/gl1", body: document.encoded())]
        )
        let lookup = #"{"data":{"id":"gl1","attributes":{"locale":"de-DE"},"#
            + #""relationships":{"subscriptionGroup":{"data":{"type":"subscriptionGroups","id":"grp1"}}}}}"#
        let transport = FakePushTransport(
            failures: ["/v1/subscriptionGroupLocalizations/gl1": Self.unmodifiable],
            remote: [
                "/v1/subscriptionGroupLocalizations/gl1?include=subscriptionGroup": Data(lookup.utf8),
                Self.groupVersions: Data((#"{"data":[{"id":"gv1","attributes":{"version":1,"state":"APPROVED"}},"#
                        + #"{"id":"gv2","attributes":{"version":2,"state":"PREPARE_FOR_SUBMISSION"}}]}"#).utf8),
                "/v1/subscriptionGroupVersions/gv2/localizations?limit=200": Data(#"{"data":[{"id":"gl9","attributes":{"locale":"de-DE"}}]}"#.utf8),
            ]
        )
        let controller = await push([change], via: transport)

        #expect(controller.doneCount == 1)
        let patch = try #require(transport.sent.last)
        #expect(patch.method == .patch)
        #expect(patch.path == "/v2/subscriptionGroupLocalizations/gl9")
        #expect(StorePageWriteDocument.decode(patch.body)?.attribute("name") == "Alba Plus")
        #expect(StorePageWriteDocument.decode(patch.body)?.attribute("locale") == nil)
    }

    @Test func onlyLegacyGroupAndSubscriptionWritesAreRead() {
        let group = StorePageWriteDocument.create(
            type: "subscriptionGroupLocalizations",
            attributes: ["locale": "de-DE", "name": "Alba"],
            parent: "subscriptionGroup",
            parentType: "subscriptionGroups",
            parentID: "grp1"
        )
        let legacy = LegacyInAppTextWrite(PushRequest(method: .post, path: "/v1/subscriptionGroupLocalizations", body: group.encoded()))
        #expect(legacy?.ownerID == "grp1")
        #expect(legacy?.lookupPath == nil)
        // Already a versions write, or something else.
        #expect(LegacyInAppTextWrite(PushRequest(method: .post, path: "/v2/subscriptionGroupLocalizations", body: group.encoded())) == nil)
        let listing = StorePageWriteDocument.update(type: "appStoreVersionLocalizations", id: "l1", attributes: ["description": "Hi"])
        #expect(LegacyInAppTextWrite(PushRequest(method: .patch, path: "/v1/appStoreVersionLocalizations/l1", body: listing.encoded())) == nil)
    }

    @Test func otherRefusalsKeepApplesWords() {
        let refusal = InAppDraftRefusal(latestVersion: 3, latestState: "APPROVED", refusal: Self.unmodifiable)
        #expect(refusal.localizedDescription.hasPrefix("App Store Connect didn’t make a new version for these texts: ENTITY_ERROR"))
    }
}
