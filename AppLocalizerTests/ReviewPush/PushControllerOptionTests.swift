//
//  PushControllerOptionTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A push with change options ("Publish to the App Store"), a resource
/// created and then used by the same change, and a secret from the Keychain.
@MainActor
@Suite("PushController · options and placeholders")
struct PushControllerOptionTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()

    private func controller(_ transport: FakePushTransport, secrets: InMemorySecretStore = InMemorySecretStore()) -> PushController {
        PushController(queue: queue, history: history, transport: transport, secrets: secrets)
    }

    /// Creates iPhone's draft, then publishes it by the ID the `POST` returned.
    private func createAndPublish(isOn: Bool) -> PendingChange {
        var change = ChangeOptionTests.change(option: nil)
        change.requests = [PushRequest(method: .post, path: "/v1/accessibilityDeclarations", body: Data("{}".utf8))]
        var option = ChangeOptionTests.option(isOn: isOn)
        option.requests = [PushRequest(
            method: .patch,
            path: "/v1/accessibilityDeclarations/\(PushRequest.createdIDPlaceholder)",
            body: Data(#"{"data":{"id":"{createdID}"}}"#.utf8)
        )]
        change.option = option
        return change
    }

    @Test func anOptionThatIsOnSendsItsRequestsWithTheCreatedID() async throws {
        let transport = FakePushTransport(responses: ["/v1/accessibilityDeclarations": Data(#"{"data":{"type":"accessibilityDeclarations","id":"d9"}}"#.utf8)])
        let push = controller(transport)
        queue.upsert(createAndPublish(isOn: true))

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == ["/v1/accessibilityDeclarations", "/v1/accessibilityDeclarations/d9"])
        let body = try #require(transport.sent.last?.body)
        #expect(String(data: body, encoding: .utf8) == #"{"data":{"id":"d9"}}"#)
        #expect(push.items.first?.status == .done)
        #expect(push.items.first?.change.option?.finishedTitle == "Published")
        #expect(queue.changes.isEmpty)
    }

    @Test func anOptionTurnedOffInReviewSendsOnlyTheChange() async {
        let transport = FakePushTransport()
        let push = controller(transport)
        queue.upsert(createAndPublish(isOn: true))
        queue.setOption(id: "a11y.iphone", isOn: false)

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == ["/v1/accessibilityDeclarations"])
        #expect(push.items.first?.change.option?.finishedTitle == "Saved as a draft")
    }

    @Test func aMissingCreatedIDFailsTheChangeAndKeepsItQueued() async {
        let push = controller(FakePushTransport())
        queue.upsert(createAndPublish(isOn: true))

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(push.items.first?.status.isFailure == true)
        #expect(queue.changes.count == 1)
    }

    @Test func aRetryReusesTheIDFromTheFirstAttempt() async {
        let transport = FakePushTransport(
            failures: ["d9": AppStoreConnectError.server(statusCode: 500, detail: nil)],
            responses: ["/v1/accessibilityDeclarations": Data(#"{"data":{"id":"d9"}}"#.utf8)]
        )
        let push = controller(transport)
        queue.upsert(createAndPublish(isOn: true))

        push.push(queue.changes)
        await push.waitUntilFinished()
        #expect(push.items.first?.createdID == "d9")
        push.retryFailed()
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == ["/v1/accessibilityDeclarations", "/v1/accessibilityDeclarations/d9", "/v1/accessibilityDeclarations/d9"])
    }

    @Test func secretsComeFromTheSecretStoreAndNeverFromTheQueue() async throws {
        let transport = FakePushTransport()
        let push = controller(transport, secrets: InMemorySecretStore(secrets: ["review.password": "sandbox-26"]))
        var change = ChangeOptionTests.change(option: nil)
        let body = #"{"demoAccountPassword":"\#(PushRequest.secretPlaceholder(named: "review.password"))"}"#
        change.requests = [PushRequest(method: .patch, path: "/v1/appStoreReviewDetails/r1", body: Data(body.utf8))]
        queue.upsert(change)
        let queued = try JSONEncoder().encode(queue.changes)
        #expect(String(data: queued, encoding: .utf8)?.contains("sandbox-26") == false)

        push.push(queue.changes)
        await push.waitUntilFinished()

        let sent = try #require(transport.sent.first?.body)
        #expect(String(data: sent, encoding: .utf8) == #"{"demoAccountPassword":"sandbox-26"}"#)
        let recorded = try JSONEncoder().encode(history.records)
        #expect(String(data: recorded, encoding: .utf8)?.contains("sandbox-26") == false)
    }

    @Test func theProgressRowKnowsWhenTheOptionIsBeingSent() {
        var item = PushItem(change: createAndPublish(isOn: true))
        item.status = .sending
        #expect(!item.isSendingOption)
        item.sentRequestCount = 1
        #expect(item.isSendingOption)
        item.change.option?.isOn = false
        #expect(!item.isSendingOption)
    }
}
