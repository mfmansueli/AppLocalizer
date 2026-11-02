//
//  ScreenshotPushRunTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// One screenshot push against a fake App Store Connect: each image is
/// reserved, uploaded in parts, committed and checked before anything live
/// is deleted, sets are reordered last, failures leave the live screenshot
/// alone, and a used-up hour pauses the push.
@MainActor
@Suite("ScreenshotPushRun")
struct ScreenshotPushRunTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    @Test func replacingImagesCommitsBeforeDeletingAndReordersLast() async {
        let transport = FakeScreenshotUploadTransport()
        let backups = InMemoryScreenshotBackupStore()
        let live = Fixtures.liveSet(.german, count: 3)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport, backups: backups))

        #expect(run.doneCount == 2)
        #expect(transport.log == [
            "reserve de-DE_iPhone_1_Today.png set-de-DE", "upload shot-1 1", "upload shot-1 2", "commit shot-1", "status shot-1",
            "reserve de-DE_iPhone_2_Week.png set-de-DE", "upload shot-2 1", "upload shot-2 2", "commit shot-2", "status shot-2",
            "delete live-de-DE-0", "delete live-de-DE-1",
            "reorder set-de-DE shot-1,shot-2,live-de-DE-2",
        ])
        #expect(transport.uploaded("shot-1") == Fixtures.png)
        #expect(run.items.allSatisfy { $0.checksum == ScreenshotPNG.checksum(Fixtures.png) })
    }

    @Test func replacedScreenshotsAreKeptOnThisMacFirst() async throws {
        let transport = FakeScreenshotUploadTransport()
        let backups = InMemoryScreenshotBackupStore()
        let live = Fixtures.liveSet(.german, count: 3)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 2])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport, backups: backups))

        let backup = try #require(backups.backup(id: run.backupID, appID: Fixtures.app.id))
        #expect(backup.images.map(\.liveID) == ["live-de-DE-0", "live-de-DE-2"])
        #expect(backup.images.map(\.position) == [0, 2])
        let image = try #require(backup.images.first)
        #expect(try backups.data(for: image, appID: Fixtures.app.id) == Data("file of live-de-DE-0".utf8))
        #expect(run.replacedSomething)
        #expect(run.subtitle == "Old screenshots were kept on this Mac. Restore them from Activity.")
    }

    @Test func aLiveScreenshotWithNoImageIsReplacedWithoutACopy() async throws {
        let transport = FakeScreenshotUploadTransport()
        let backups = InMemoryScreenshotBackupStore()
        let live = Fixtures.liveSet(.german, count: 2)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 1])])
        let environment = Fixtures.environment(transport, backups: backups, liveData: { shot in
            if shot.id == "live-de-DE-0" { throw LiveScreenshotImageError.noImage }
            return Data("file of \(shot.id)".utf8)
        })
        let run = await Fixtures.push([plan], environment: environment)

        #expect(run.doneCount == 2)
        #expect(transport.log.contains("delete live-de-DE-0"))
        #expect(run.items.first?.note == "The live screenshot had no image in App Store Connect (its upload never finished or Apple "
            + "couldn’t process it), so there was nothing to keep.")
        #expect(run.items.last?.note == nil)
        let backup = try #require(backups.backup(id: run.backupID, appID: Fixtures.app.id))
        #expect(backup.images.map(\.liveID) == ["live-de-DE-1"])
    }

    @Test func aLiveScreenshotStillProcessingIsLeftAlone() async throws {
        let transport = FakeScreenshotUploadTransport()
        let live = Fixtures.liveSet(.german, count: 2)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 1])])
        let environment = Fixtures.environment(transport, liveData: { shot in
            if shot.id == "live-de-DE-1" { throw LiveScreenshotImageError.stillProcessing }
            return Data("file of \(shot.id)".utf8)
        })
        let run = await Fixtures.push([plan], environment: environment)

        #expect(run.doneCount == 1)
        let failed = try #require(run.items.first { $0.status.isFailure })
        #expect(failed.status.failureText == "The live screenshot is still processing in App Store Connect, so it wasn’t replaced. Try again in a few minutes.")
        #expect(!transport.log.contains("reserve de-DE_iPhone_2_Week.png set-de-DE"))
        #expect(!transport.log.contains("delete live-de-DE-1"))
    }

    @Test func aNewSetIsCreatedForTheLocalization() async {
        let transport = FakeScreenshotUploadTransport()
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(transport.log.first == "create-set APP_IPHONE_67 loc-ar-SA")
        #expect(transport.log.contains("reserve ar-SA_iPhone_1_Today.png set-1"))
        #expect(!transport.log.contains { $0.hasPrefix("delete") || $0.hasPrefix("reorder") })
        #expect(run.title == "All 2 images pushed")
    }

    /// English (U.S.)'s iPhone Duo set was there, empty, from an upload
    /// that never finished: the push fills it instead of creating another,
    /// which App Store Connect refuses ("Screenshot Set Already Exists!").
    @Test func anEmptySetAppStoreConnectHasIsFilledNotCreated() async {
        let transport = FakeScreenshotUploadTransport()
        var group = Fixtures.group(.arabic, display: .iPhoneDuo, live: nil, slots: [0, 1])
        group.emptySetID = "set-empty"
        let run = await Fixtures.push([Fixtures.plan([group])], environment: Fixtures.environment(transport))

        #expect(!transport.log.contains { $0.hasPrefix("create-set") })
        #expect(transport.log.count { $0.hasPrefix("reserve ") && $0.hasSuffix(" set-empty") } == 2)
        #expect(run.title == "All 2 images pushed")
    }

    /// A set made after the push was planned: the refused create looks it
    /// up and fills it while it's empty.
    @Test func aRefusedCreateFillsTheEmptySetThatsThere() async {
        let transport = FakeScreenshotUploadTransport(.init(existingSets: ["APP_IPHONE_DUO loc-ar-SA": ("set-there", 0)]))
        let plan = Fixtures.plan([Fixtures.group(.arabic, display: .iPhoneDuo, live: nil, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(Array(transport.log.prefix(2)) == ["create-set APP_IPHONE_DUO loc-ar-SA refused", "find-set APP_IPHONE_DUO loc-ar-SA"])
        #expect(transport.log.count { $0.hasPrefix("reserve ") && $0.hasSuffix(" set-there") } == 2)
        #expect(run.title == "All 2 images pushed")
    }

    /// One with screenshots the push hasn't seen is left alone.
    @Test func aSetWithScreenshotsThePushHasntSeenIsLeftAlone() async throws {
        let transport = FakeScreenshotUploadTransport(.init(existingSets: ["APP_IPHONE_DUO loc-ar-SA": ("set-there", 3)]))
        let plan = Fixtures.plan([Fixtures.group(.arabic, display: .iPhoneDuo, live: nil, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(run.failedCount == 2)
        let text = try #require(run.items.first?.status.failureText)
        #expect(text.hasPrefix(
            "App Store Connect already has iPhone Duo screenshots for Arabic that this push hasn’t seen. Refresh, review them and push again."
        ))
        #expect(!transport.log.contains { $0.hasPrefix("reserve") })
    }

    /// The percentage moves as the bytes go out, never back, and only
    /// while the image is uploading.
    @Test func theUploadPercentageFollowsTheBytesSent() {
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0])])
        let run = ScreenshotPushRun(plans: [plan], selection: nil, environment: Fixtures.environment(FakeScreenshotUploadTransport()))
        run.items[0].status = .uploading(0)
        run.noteSent(0, bytes: 256, of: 1024)
        #expect(run.items[0].status == .uploading(0.25))
        #expect(run.items[0].status.stepTitle == "Uploading 25%")
        run.noteSent(0, bytes: 128, of: 1024)
        #expect(run.items[0].status == .uploading(0.25))
        run.noteSent(0, bytes: 4096, of: 1024)
        #expect(run.items[0].status == .uploading(1))
        run.items[0].status = .committing
        run.noteSent(0, bytes: 1024, of: 1024)
        #expect(run.items[0].status == .committing)
    }

    @Test func aTimedOutPartFailsOnlyThatImageAndLeavesTheLiveOne() async throws {
        let transport = FakeScreenshotUploadTransport(.init(timeouts: ["de-DE_iPhone_2_": 2]))
        let live = Fixtures.liveSet(.german, count: 3)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(run.doneCount == 1)
        let failed = try #require(run.items.first { $0.status.isFailure })
        #expect(failed.status.failureText == "Upload timed out on part 2 of 2. Nothing was replaced; the live screenshot stays.")
        #expect(transport.log.contains("delete shot-2"))
        #expect(!transport.log.contains("delete live-de-DE-1"))
        #expect(transport.log.last == "reorder set-de-DE shot-1,live-de-DE-1,live-de-DE-2")
        #expect(run.title == "1 of 2 images pushed")
        #expect(run.subtitle == "1 failed. Its live screenshot wasn’t touched.")
    }

    @Test func appleFailingToProcessDropsTheImage() async throws {
        let transport = FakeScreenshotUploadTransport(.init(processingFailures: ["es-MX_iPhone_2_"]))
        let plan = Fixtures.plan([Fixtures.group(.spanishMexico, live: nil, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        let failed = try #require(run.items.first { $0.status.isFailure })
        #expect(failed.status.failureText == "Apple couldn’t process the image (IMAGE_TOOL_FAILURE). The live screenshot stays.")
        #expect(transport.log.contains("delete shot-3"))
    }

    @Test func retryFailedSendsOnlyTheFailedImages() async {
        let transport = FakeScreenshotUploadTransport(.init(timeouts: ["de-DE_iPhone_2_": 1]))
        let live = Fixtures.liveSet(.german, count: 2)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))
        #expect(run.failedCount == 1)
        let before = transport.log.count

        run.retryFailed()
        await run.waitUntilFinished()

        #expect(run.doneCount == 2)
        #expect(run.roundItemIDs.count == 1)
        let retried = transport.log.dropFirst(before)
        #expect(retried.first == "reserve de-DE_iPhone_2_Week.png set-de-DE")
        #expect(retried.contains("delete live-de-DE-1"))
        #expect(!retried.contains("delete live-de-DE-0"))
    }

    @Test func cancelRemainingLetsTheImageInFlightFinish() async {
        let transport = FakeScreenshotUploadTransport()
        let plans = [Fixtures.plan([
            Fixtures.group(.arabic, live: nil, slots: [0, 1]),
            Fixtures.group(.dutch, live: nil, slots: [0]),
        ])]
        var started: ScreenshotPushRun?
        let environment = Fixtures.environment(transport) { _ in
            started?.cancelRemaining()
            return Fixtures.png
        }
        let run = ScreenshotPushRun(plans: plans, environment: environment)
        started = run
        run.start()
        await run.waitUntilFinished()

        #expect(run.items.map(\.status) == [.done, .cancelled, .cancelled])
        #expect(!transport.log.contains { $0.contains("loc-nl-NL") })
    }

    @Test func goingOfflineStopsTheRest() async {
        let transport = FakeScreenshotUploadTransport(.init(offline: ["ar-SA_iPhone_1_"]))
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0, 1])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(run.items.map(\.status) == [.notSent("Not sent · offline"), .notSent("Not sent · offline")])
        #expect(run.subtitle == "2 not sent. They stay in Review & Push.")
    }

    @Test func aFullSetMakesRoomByDeletingTheReplacedScreenshotFirst() async {
        let transport = FakeScreenshotUploadTransport()
        let live = Fixtures.liveSet(.german, count: 10)
        let plan = Fixtures.plan([Fixtures.group(.german, live: live, slots: [3])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport))

        #expect(run.doneCount == 1)
        #expect(Array(transport.log.prefix(2)) == ["delete live-de-DE-3", "reserve de-DE_iPhone_4_Photos.png set-de-DE"])
        #expect(transport.log.filter { $0.hasPrefix("delete") } == ["delete live-de-DE-3"])
    }

    @Test func onlyTheSelectedImagesGo() async {
        let transport = FakeScreenshotUploadTransport()
        let group = Fixtures.group(.arabic, live: nil, slots: [0, 1, 2])
        let run = await Fixtures.push([Fixtures.plan([group])], selection: [group.items[1].id], environment: Fixtures.environment(transport))
        #expect(run.totalCount == 1)
        #expect(transport.log.contains("reserve ar-SA_iPhone_2_Week.png set-1"))
    }

    @Test func aBlockedPlanSendsNothing() {
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0])], version: ScreenshotsTestFixtures.liveVersion)
        var blocked = plan
        blocked.blockedReason = "Version 1.3 is live."
        let run = ScreenshotPushRun(plans: [blocked], environment: Fixtures.environment(FakeScreenshotUploadTransport()))
        #expect(run.items.isEmpty)
    }

    // MARK: - Budget

    @Test func aUsedUpHourPausesUntilTheNextOne() async {
        let clock = ScreenshotPushTestClock()
        let rate = RequestRateTracker(now: { clock.now }, reported: AppStoreConnectRateLimit(limit: 3600, remaining: 0))
        let transport = FakeScreenshotUploadTransport()
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport, clock: clock, rate: rate))

        #expect(run.doneCount == 1)
        #expect(clock.now >= ScreenshotPushTestClock.october12.addingTimeInterval(27 * 60 + 55))
        #expect(rate.rateLimit.remaining == 3000 - transport.log.count(where: { !$0.hasPrefix("upload") }))
    }

    @Test func aRateLimitedRequestIsSentAgainAfterThePause() async {
        let clock = ScreenshotPushTestClock()
        let transport = FakeScreenshotUploadTransport(.init(rateLimitedOnce: true))
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0])])
        let run = await Fixtures.push([plan], environment: Fixtures.environment(transport, clock: clock))

        #expect(run.doneCount == 1)
        #expect(transport.log.first == "create-set APP_IPHONE_67 loc-ar-SA")
        #expect(clock.now > ScreenshotPushTestClock.october12)
    }

    @Test func requestsFeedTheHourlyMeter() async {
        let rate = RequestRateTracker()
        let transport = FakeScreenshotUploadTransport(.init(remaining: 3228))
        let plan = Fixtures.plan([Fixtures.group(.arabic, live: nil, slots: [0])])
        _ = await Fixtures.push([plan], environment: Fixtures.environment(transport, rate: rate))
        // create-set, reserve, commit and status; the parts go to Apple's
        // upload host.
        #expect(rate.rateLimit.remaining == 3224)
    }

    @Test func setsRunAFewAtATime() async {
        let transport = FakeScreenshotUploadTransport()
        let groups = [StoreLocale.arabic, .dutch, .spanishMexico, .chineseSimplified].map { Fixtures.group($0, live: nil, slots: [0]) }
        let run = await Fixtures.push([Fixtures.plan(groups)], environment: Fixtures.environment(transport, concurrentSets: 3))
        #expect(run.doneCount == 4)
        #expect(transport.log.count { $0.hasPrefix("create-set") } == 4)
    }
}
#endif
