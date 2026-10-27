//
//  PushControllerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("PushController")
struct PushControllerTests {
    private let queue = ChangeQueue()
    private let history = PushHistory()

    private func controller(_ transport: FakePushTransport) -> PushController {
        let controller = PushController(queue: queue, history: history, transport: transport)
        controller.appName = { "App \($0)" }
        return controller
    }

    @Test func pushesInOrderRemovesPushedChangesAndRecordsThem() async {
        let transport = FakePushTransport()
        let push = controller(transport)
        var pushedApps: Set<StoreApp.ID> = []
        push.onPushed = { pushedApps = $0 }
        queue.upsert(contentsOf: [PushFixtures.price("BRA"), PushFixtures.price("MEX"), PushFixtures.listing("Subtitle", app: "habitat")])

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == ["/v1/subscriptionPrices/BRA", "/v1/subscriptionPrices/MEX", "/v1/appStoreVersionLocalizations/de-Subtitle"])
        #expect(queue.changes.isEmpty)
        #expect(push.phase == .finished)
        #expect(push.doneCount == 3)
        #expect(push.title == "3 pushed")
        #expect(pushedApps == ["lumen", "habitat"])
        #expect(history.records.count == 2)
        #expect(history.lastRecord(for: "lumen")?.title == "Subscription Pricing · BRA, MEX")
        #expect(history.lastRecord(for: "habitat")?.appName == "App habitat")
        #expect(push.notice == nil)
    }

    @Test func failuresStayQueuedWithApplesTextAndAreRetried() async {
        let rejected = AppStoreConnectError.rejected(statusCode: 409, code: "ENTITY_ERROR.RELATIONSHIP.INVALID", detail: "Not available.")
        let transport = FakePushTransport(failures: ["CHL": rejected])
        let push = controller(transport)
        queue.upsert(contentsOf: [PushFixtures.price("BRA"), PushFixtures.price("CHL")])

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(queue.changes.map(\.id) == ["price.annual.CHL"])
        #expect(push.items.last?.status == .failed("ENTITY_ERROR.RELATIONSHIP.INVALID — Not available."))
        #expect(push.title == "1 pushed · 1 failed")
        #expect(push.notice == .partialFailure(failed: 1, total: 2))
        #expect(history.lastRecord(for: "lumen")?.failures["price.annual.CHL"] == "ENTITY_ERROR.RELATIONSHIP.INVALID — Not available.")

        push.retryFailed()
        await push.waitUntilFinished()
        #expect(transport.sent.count == 3)
        #expect(push.items.last?.status.isFailure == true)
    }

    @Test func retryResumesAfterRequestsThatWentThrough() async {
        let transport = FakePushTransport(failures: ["second": AppStoreConnectError.server(statusCode: 500, detail: nil)])
        let push = controller(transport)
        var change = PushFixtures.price("BRA")
        change.requests = [PushRequest(method: .post, path: "/first"), PushRequest(method: .post, path: "/second")]
        queue.upsert(change)

        push.push(queue.changes)
        await push.waitUntilFinished()
        push.retryFailed()
        await push.waitUntilFinished()

        #expect(transport.sent.map(\.path) == ["/first", "/second", "/second"])
    }

    @Test func aValueChangedInAppStoreConnectGoesBackToReview() async {
        let transport = FakePushTransport(remote: ["/v1/check": Data(#"{"data":{"attributes":{"customerPrice":"199.9"}}}"#.utf8)])
        let push = controller(transport)
        var change = PushFixtures.price("BRA")
        change.conflictCheck = ConflictCheck(
            path: "/v1/check",
            keyPath: ["data", "attributes", "customerPrice"],
            expected: "219.90",
            format: .currency(code: "BRL", localeIdentifier: "pt_BR")
        )
        queue.upsert(change)

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.fetched == ["/v1/check"])
        #expect(transport.sent.isEmpty)
        #expect(push.items.first?.status == .conflict)
        let conflict = queue.change(id: change.id)?.remoteConflict
        #expect(conflict?.remoteRawValue == "199.9")
        #expect(conflict?.remoteDisplayValue.contains("199,90") == true)
        #expect(queue.change(id: change.id)?.isBlocked == true)
    }

    @Test func anUnchangedValuePushes() async {
        let transport = FakePushTransport(remote: ["/v1/check": Data(#"{"data":{"attributes":{"customerPrice":"219.9"}}}"#.utf8)])
        let push = controller(transport)
        var change = PushFixtures.price("BRA")
        change.conflictCheck = ConflictCheck(path: "/v1/check", keyPath: ["data", "attributes", "customerPrice"], expected: "219.90")
        queue.upsert(change)

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.count == 1)
        #expect(queue.changes.isEmpty)
    }

    @Test func rateLimitStopsTheRestWithoutLosingThem() async {
        let transport = FakePushTransport(failures: ["MEX": AppStoreConnectError.rateLimited])
        let push = controller(transport)
        queue.upsert(contentsOf: ["BRA", "MEX", "ARG"].map { PushFixtures.price($0) })

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.count == 2)
        #expect(queue.changes.map(\.title) == ["MEX", "ARG"])
        #expect(push.items.map(\.status) == [.done, .notSent("Rate limited"), .notSent("Rate limited")])
        if case .rateLimited = push.notice {} else { Issue.record("expected a rate-limit notice") }
    }

    @Test func goingOfflineStopsWithANotice() async {
        let transport = FakePushTransport(failures: ["BRA": URLError(.notConnectedToInternet)])
        let push = controller(transport)
        queue.upsert(contentsOf: ["BRA", "MEX"].map { PushFixtures.price($0) })

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(transport.sent.count == 1)
        #expect(push.notice == .offline)
        #expect(queue.totalCount == 2)
    }

    @Test func blockedChangesAreLeftInReview() async {
        let transport = FakePushTransport()
        let push = controller(transport)
        var blocked = PushFixtures.listing("Subtitle")
        blocked.blockedReason = "Over the limit, 31 of 30 characters"
        queue.upsert(contentsOf: [blocked, PushFixtures.price("BRA")])

        push.push(queue.changes)
        await push.waitUntilFinished()

        #expect(push.items.map(\.id) == ["price.annual.BRA"])
        #expect(queue.changes.map(\.id) == [blocked.id])
    }

    @Test func discardedMeanwhileIsNotSent() async {
        let transport = FakePushTransport()
        let push = controller(transport)
        queue.upsert(contentsOf: ["BRA", "MEX"].map { PushFixtures.price($0) })
        let changes = queue.changes
        queue.discard(id: "price.annual.MEX")

        push.push(changes)
        await push.waitUntilFinished()

        #expect(transport.sent.count == 1)
        #expect(push.items.last?.status == .notSent("Discarded"))
    }

    @Test func rateMeterUsesApplesHeaderWhenItHasOne() async {
        let transport = FakePushTransport(rateLimit: AppStoreConnectRateLimit(limit: 3600, remaining: 3143))
        let push = controller(transport)
        #expect(push.rateLimit.used == 0)
        queue.upsert(PushFixtures.price("BRA"))
        push.push(queue.changes)
        await push.waitUntilFinished()
        #expect(push.rateLimit.used == 457)
    }

    @Test func dismissingAFinishedPushClearsTheList() async {
        let push = controller(FakePushTransport())
        queue.upsert(PushFixtures.price("BRA"))
        push.push(queue.changes)
        await push.waitUntilFinished()
        push.dismissFinished()
        #expect(push.phase == .idle)
        #expect(push.items.isEmpty)
    }
}
