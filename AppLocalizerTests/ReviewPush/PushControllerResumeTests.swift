//
//  PushControllerResumeTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A change that stopped partway picks up after what App Store Connect
/// already took, unless it was edited since: then it all goes again.
@MainActor
@Suite("PushController · picking a stopped change up")
struct PushControllerResumeTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()
    private let transport = FakePushTransport(failures: [
        "/v1/second": AppStoreConnectError.rejected(statusCode: 409, code: "STATE_ERROR", detail: "Not now."),
    ])

    private func controller() -> PushController {
        PushController(queue: queue, history: history, transport: transport, secrets: InMemorySecretStore())
    }

    private static func change(_ paths: [String]) -> PendingChange {
        var change = ChangeOptionTests.change(option: nil)
        change.requests = paths.map { PushRequest(method: .patch, path: $0) }
        return change
    }

    /// Pushes first + second; second fails.
    private func stopped() async -> PushController {
        let push = controller()
        queue.upsert(Self.change(["/v1/first", "/v1/second"]))
        push.push(queue.changes)
        await push.waitUntilFinished()
        return push
    }

    @Test func aRetryResumesAfterWhatWentThrough() async {
        let push = await stopped()
        push.retryFailed()
        await push.waitUntilFinished()
        #expect(transport.sent.map(\.path) == ["/v1/first", "/v1/second", "/v1/second"])
    }

    @Test func aRetryAfterAnEditSendsItAllAgain() async {
        let push = await stopped()
        queue.upsert(Self.change(["/v1/edited", "/v1/third"]))
        push.retryFailed()
        await push.waitUntilFinished()
        #expect(transport.sent.map(\.path) == ["/v1/first", "/v1/second", "/v1/edited", "/v1/third"])
    }

    @Test func closingThePushAndPushingAgainResumes() async {
        let push = await stopped()
        push.dismissFinished()
        push.push(queue.changes)
        await push.waitUntilFinished()
        #expect(transport.sent.map(\.path) == ["/v1/first", "/v1/second", "/v1/second"])
    }

    @Test func editingAfterClosingStartsOver() async {
        let push = await stopped()
        push.dismissFinished()
        queue.upsert(Self.change(["/v1/edited", "/v1/second"]))
        push.push(queue.changes)
        await push.waitUntilFinished()
        #expect(transport.sent.map(\.path) == ["/v1/first", "/v1/second", "/v1/edited", "/v1/second"])
    }
}
