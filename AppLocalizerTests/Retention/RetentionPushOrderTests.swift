//
//  RetentionPushOrderTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Apple refuses a retention offer until its subscription has a message, so
/// a push sends each app's messages before its offers, however they queued.
@MainActor
@Suite("Retention · messages go before offers")
struct RetentionPushOrderTests {
    private static func change(id: String, app: StoreApp.ID, path: String, blockedReason: String? = nil) -> PendingChange {
        PendingChange(
            id: id,
            appID: app,
            section: .subscriptionPricing,
            group: "Retention",
            title: id,
            oldValue: "",
            newValue: id,
            blockedReason: blockedReason,
            requests: [PushRequest(method: .patch, path: path)]
        )
    }

    private static func message(_ name: String, app: StoreApp.ID = "1", blockedReason: String? = nil) -> PendingChange {
        change(
            id: RetentionChangeBuilder.messageChangeID(appID: app, messageID: name),
            app: app,
            path: "/v1/\(name)",
            blockedReason: blockedReason
        )
    }

    private static func offer(_ name: String, app: StoreApp.ID = "1") -> PendingChange {
        change(
            id: RetentionChangeBuilder.offerChangeID(appID: app, subscriptionID: "sub", offerID: name),
            app: app,
            path: "/v1/\(name)"
        )
    }

    private static func other(_ name: String, app: StoreApp.ID = "1") -> PendingChange {
        change(id: "price.\(name)", app: app, path: "/v1/\(name)")
    }

    private static func paths(_ changes: [PendingChange]) -> [String] {
        changes.flatMap(\.requests).map(\.path)
    }

    @Test func anOfferQueuedFirstGoesAfterItsMessage() {
        let sorted = RetentionPushOrder.sorted([Self.offer("offer"), Self.message("message")])
        #expect(Self.paths(sorted) == ["/v1/message", "/v1/offer"])
    }

    @Test func everythingElseKeepsItsPlace() {
        let sorted = RetentionPushOrder.sorted([
            Self.other("a"), Self.offer("offer"), Self.other("b"), Self.message("message"), Self.other("c"),
        ])
        #expect(Self.paths(sorted) == ["/v1/a", "/v1/b", "/v1/message", "/v1/offer", "/v1/c"])
    }

    @Test func offersWaitForTheLastMessageAndKeepTheirOrder() {
        let sorted = RetentionPushOrder.sorted([
            Self.offer("offer1"), Self.message("message1"), Self.offer("offer2"), Self.message("message2"),
        ])
        #expect(Self.paths(sorted) == ["/v1/message1", "/v1/message2", "/v1/offer1", "/v1/offer2"])
    }

    @Test func anotherAppsMessageDoesNotHoldAnOffer() {
        let changes = [Self.offer("offer", app: "1"), Self.message("message", app: "2")]
        #expect(Self.paths(RetentionPushOrder.sorted(changes)) == ["/v1/offer", "/v1/message"])
    }

    @Test func anOfferWithNoMessageStaysPut() {
        let changes = [Self.other("a"), Self.offer("offer"), Self.other("b")]
        #expect(Self.paths(RetentionPushOrder.sorted(changes)) == ["/v1/a", "/v1/offer", "/v1/b"])
    }

    @Test func anOfferAlreadyAfterItsMessageStaysThere() {
        let changes = [Self.message("message"), Self.other("a"), Self.offer("offer")]
        #expect(Self.paths(RetentionPushOrder.sorted(changes)) == ["/v1/message", "/v1/a", "/v1/offer"])
    }

    // MARK: - Through a push

    private func push(_ changes: [PendingChange]) async -> [String] {
        let queue = ChangeQueue()
        let transport = FakePushTransport()
        let controller = PushController(queue: queue, history: PushHistory(), transport: transport, secrets: InMemorySecretStore())
        queue.upsert(contentsOf: changes)
        controller.push(queue.changes)
        await controller.waitUntilFinished()
        return transport.sent.map(\.path)
    }

    @Test func aPushSendsTheMessageFirst() async {
        let sent = await push([Self.offer("offer"), Self.message("message")])
        #expect(sent == ["/v1/message", "/v1/offer"])
    }

    @Test func aBlockedMessageDoesNotHoldTheOfferBack() async {
        let sent = await push([Self.offer("offer"), Self.message("message", blockedReason: "No name.")])
        #expect(sent == ["/v1/offer"])
    }
}
