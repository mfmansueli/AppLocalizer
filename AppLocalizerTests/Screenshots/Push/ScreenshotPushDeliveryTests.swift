//
//  ScreenshotPushDeliveryTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Apple processes a committed file afterwards and can still fail it: the
/// old screenshot goes only once the new one is confirmed.
@MainActor
@Suite("ScreenshotPushRun · delivery")
struct ScreenshotPushDeliveryTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    private static func replacingFirst() -> ScreenshotPushPlan {
        Fixtures.plan([Fixtures.group(.german, live: Fixtures.liveSet(.german, count: 3), slots: [0])])
    }

    @Test func theOldScreenshotWaitsUntilTheNewOneIsProcessed() async throws {
        let transport = FakeScreenshotUploadTransport(.init(processingChecks: ["de-DE_iPhone_1_": 2]))
        let run = await Fixtures.push([Self.replacingFirst()], environment: Fixtures.environment(transport))

        #expect(run.doneCount == 1)
        let log = transport.log
        #expect(log.filter { $0 == "status shot-1" }.count == 3)
        let deleted = try #require(log.firstIndex(of: "delete live-de-DE-0"))
        let confirmed = try #require(log.lastIndex(of: "status shot-1"))
        #expect(deleted > confirmed)
    }

    @Test func anImageApplePassesThenFailsLeavesTheOldOne() async throws {
        let transport = FakeScreenshotUploadTransport(.init(failsLater: ["de-DE_iPhone_1_"]))
        let run = await Fixtures.push([Self.replacingFirst()], environment: Fixtures.environment(transport))

        let failed = try #require(run.items.first)
        #expect(failed.status.failureText == "Apple couldn’t process the image (IMAGE_TOOL_FAILURE). The live screenshot stays.")
        #expect(transport.log.contains("delete shot-1"))
        #expect(!transport.log.contains("delete live-de-DE-0"))
    }

    @Test func oneStillProcessingKeepsTheOldOneBesideIt() async {
        let transport = FakeScreenshotUploadTransport(.init(processingChecks: ["de-DE_iPhone_1_": 100]))
        var environment = Fixtures.environment(transport)
        environment.deliveryChecks = 3
        let run = await Fixtures.push([Self.replacingFirst()], environment: environment)

        #expect(transport.log.filter { $0 == "status shot-1" }.count == 4)
        #expect(!transport.log.contains("delete live-de-DE-0"))
        #expect(run.items.first?.note == "Apple is still processing this image, so the old screenshot stays beside it for now.")
    }

    @Test func aFullSetThatFailsSaysTheOldOneWasRemoved() async throws {
        let transport = FakeScreenshotUploadTransport(.init(timeouts: ["de-DE_iPhone_4_": 1]))
        let plan = Fixtures.plan([Fixtures.group(.german, live: Fixtures.liveSet(.german, count: 10), slots: [3])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        let failed = try #require(run.items.first)
        #expect(failed.status.isFailure)
        #expect(failed.isOldDeleted)
        #expect(failed.note == "The live screenshot was removed to make room in the full set. Restore it from Activity.")
        #expect(run.replacedSomething)
    }

    @Test func retryUnsentSendsWhatCancellingLeft() async {
        let transport = FakeScreenshotUploadTransport()
        let plans = [Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0, 1])])]
        var started: ScreenshotPushRun?
        let environment = Fixtures.environment(transport) { _ in
            started?.cancelRemaining()
            return Fixtures.png
        }
        let run = ScreenshotPushRun(plans: plans, environment: environment)
        started = run
        run.start()
        await run.waitUntilFinished()
        #expect(run.items.map(\.status) == [.done, .cancelled])
        started = nil

        run.retryUnsent()
        await run.waitUntilFinished()
        #expect(run.doneCount == 2)
    }
}
#endif
