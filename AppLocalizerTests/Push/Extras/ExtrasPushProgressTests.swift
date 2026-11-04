//
//  ExtrasPushProgressTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The extras push keeps uploading while Apple processes what it sent, and
/// says what it's doing: each item in flight and its step, a waiting
/// item's place in line, what finished, the time so far and about how
/// long is left, a pause and a cancel.
@MainActor
@Suite("Extras push progress")
struct ExtrasPushProgressTests {
    private typealias Fixtures = ExtrasPushFixtures

    // MARK: - Uploading while Apple processes

    /// The header is processed only once the preview is reserved: one
    /// file at a time it never is, so it times out.
    @Test func theNextFileUploadsWhileAppleProcessesTheOneBefore() async throws {
        var script = FakeAssetLibrary.Script()
        script.processingUntilReserved = ["de-DE-header": "de-DE-preview"]
        let header = Fixtures.header()
        let preview = Fixtures.preview()

        let overlapping = FakeAssetLibrary(script)
        let run = await Fixtures.push(
            [header, preview], environment: Fixtures.environment(overlapping, processingTimeout: .seconds(600), processingWindow: 3)
        )
        #expect(run.status(of: header).isDone)
        #expect(run.status(of: preview).isDone)
        let log = overlapping.log
        let reservedPreview = log.firstIndex { $0.hasPrefix("reserve video") }
        let placedHeader = log.firstIndex { $0.hasPrefix("place image-1") }
        #expect(try reservedPreview != nil && placedHeader != nil && #require(reservedPreview) < #require(placedHeader), "\(log)")

        let oneByOne = FakeAssetLibrary(script)
        let sequential = await Fixtures.push(
            [header, preview], environment: Fixtures.environment(oneByOne, processingTimeout: .seconds(5), processingWindow: 1)
        )
        #expect(sequential.status(of: header) == .failed("Apple was still processing the file. It’s uploaded; Retry Failed places it once it’s ready."))
    }

    @Test func itDefaultsToTenFilesWithAppleAtOnce() {
        #expect(ExtrasPushEnvironment(library: FakeAssetLibrary(), rate: RequestRateTracker()).processingWindow == 10)
    }

    @Test func waitingForRoomSaysSo() {
        let clock = ScreenshotPushTestClock()
        let items = [Fixtures.header(), Fixtures.wide(), Fixtures.preview()]
        let run = ExtrasPushRun(items: items, environment: Fixtures.environment(FakeAssetLibrary(), clock: clock, processingWindow: 2))
        run.phase = .running
        for item in items.prefix(2) {
            run.activities[item.id] = ExtrasPushActivity(itemID: item.id, startedAt: clock.now, stepStartedAt: clock.now)
        }
        #expect(run.roomTitle == nil)
        run.waitsForRoom = true
        #expect(run.roomTitle == "2 files are with Apple; the next uploads as soon as one is placed.")
        run.pausedUntil = clock.now.addingTimeInterval(60)
        #expect(run.roomTitle == nil, "The pause says why instead")
    }

    @Test func failuresAreListedOncePerReason() {
        let items = [Fixtures.header(), Fixtures.wide(), Fixtures.preview()]
        let run = ExtrasPushRun(items: items, environment: Fixtures.environment(FakeAssetLibrary()))
        run.statuses[items[0].id] = .failed("Taken.")
        run.statuses[items[1].id] = .failed("Offline.")
        run.statuses[items[2].id] = .failed("Taken.")
        #expect(run.failureGroups.map(\.reason) == ["Taken.", "Offline."])
        #expect(run.failureGroups.first?.items == [items[0], items[2]])
        #expect(run.failureGroups.first?.itemsTitle == "German · Header 21:9 and German · App Preview")
    }

    // MARK: - What it says

    @Test func itNamesTheItemInFlightAndWhereTheOthersAreInLine() async {
        let holder = ExtrasPushRunHolder()
        let library = FakeAssetLibrary(onReserve: { await holder.noteProgress() })
        let header = Fixtures.header()
        let wide = Fixtures.wide()
        let preview = Fixtures.preview()
        let run = ExtrasPushRun(items: [header, wide, preview], environment: Fixtures.environment(library))
        holder.run = run
        run.start()
        await run.waitUntilFinished()

        #expect(holder.progress[header.id]?.hasPrefix("Uploading 0% · ") == true, "\(holder.progress)")
        #expect(holder.progress[wide.id] == "Next")
        #expect(holder.progress[preview.id] == "Waiting · 1 ahead")

        #expect(run.activities.isEmpty, "Nothing's in flight once it's over")
        #expect(run.events.map(\.itemID) == [header.id, wide.id, preview.id])
        #expect(run.events.map(\.text) == [
            "Placed on the product page header", "Placed on the product page header and search results", "Placed first in App Previews",
        ])
        #expect(run.events.allSatisfy { $0.seconds >= 1 }, "Each waited for one processing check")
    }

    @Test func eachStepSaysHowFarItGot() {
        let header = Fixtures.header()
        let preview = Fixtures.preview()
        let clock = ScreenshotPushTestClock()
        let run = ExtrasPushRun(items: [header, preview], environment: Fixtures.environment(FakeAssetLibrary(), clock: clock))
        let now = clock.now
        run.activities[header.id] = ExtrasPushActivity(
            itemID: header.id, startedAt: now, stepStartedAt: now.addingTimeInterval(-42), sentBytes: 0, totalBytes: 0, checks: 3
        )
        run.statuses[header.id] = .processing
        #expect(run.stepDetail(of: header, now: now) == "Apple is processing it · 0:42 · checked 3 times")
        run.statuses[header.id] = .placing
        #expect(run.stepDetail(of: header, now: now) == "Placing it on the product page header")
        run.statuses[header.id] = .preparing
        #expect(run.stepDetail(of: header, now: now) == "Getting ready: reading Apple’s sizes and the app’s asset library")

        run.activities[preview.id] = ExtrasPushActivity(itemID: preview.id, startedAt: now, stepStartedAt: now)
        run.statuses[preview.id] = .placing
        #expect(run.stepDetail(of: preview, now: now) == "Placing it first in App Previews")
        run.statuses[preview.id] = .uploading(0.5)
        #expect(run.stepDetail(of: preview, now: now) == "Uploading 50%", "Before the file is read")
        #expect(run.itemsInFlight == [header, preview])
    }

    @Test func theTimeLeftFollowsThePace() {
        let clock = ScreenshotPushTestClock()
        let items = [Fixtures.header(), Fixtures.wide(), Fixtures.preview()]
        let run = ExtrasPushRun(items: items, environment: Fixtures.environment(FakeAssetLibrary(), clock: clock))
        run.phase = .running
        run.startedAt = clock.now
        let now = clock.now.addingTimeInterval(60)
        #expect(run.timeTitle(now: now) == "1:00 so far", "Nothing finished yet")

        run.statuses[items[0].id] = .done(assetID: "a", placementIDs: [])
        run.events = [ExtrasPushEvent(id: 0, item: items[0], status: run.status(of: items[0]), date: now, seconds: 60)]
        #expect(run.remainingSeconds(now: now) == 120)
        #expect(run.timeTitle(now: now) == "1:00 so far · about 2 min left")
        #expect(run.countTitle == "1 of 3 done")

        run.statuses[items[1].id] = .failed("Why.")
        run.events.append(ExtrasPushEvent(id: 1, item: items[1], status: .failed("Why."), date: now, seconds: 20))
        #expect(run.countTitle == "1 of 3 done · 1 failed")
        // Two finished in a minute: the last one takes about 30 seconds.
        #expect(run.remainingSeconds(now: now) == 30)
        #expect(run.timeTitle(now: now) == "1:00 so far · less than a minute left")

        run.pausedUntil = clock.now.addingTimeInterval(3600)
        #expect(run.timeTitle(now: now) == "1:00 so far", "No estimate while it's paused")
        #expect(run.pauseTitle?.hasPrefix("Paused until ") == true)
        #expect(run.pauseTitle?.hasSuffix("App Store Connect’s hourly request limit is used up. It goes on by itself.") == true)
    }

    @Test func cancellingSaysWhatStillFinishes() {
        let clock = ScreenshotPushTestClock()
        let items = [Fixtures.header(), Fixtures.wide(), Fixtures.preview()]
        let run = ExtrasPushRun(items: items, environment: Fixtures.environment(FakeAssetLibrary(), clock: clock))
        run.phase = .running
        #expect(run.cancellingTitle == nil)
        #expect(run.queueTitle(of: items[2]) == "Waiting · 2 ahead")

        run.isCancelling = true
        for item in items.prefix(2) {
            run.activities[item.id] = ExtrasPushActivity(itemID: item.id, startedAt: clock.now, stepStartedAt: clock.now)
        }
        #expect(run.cancellingTitle == "Cancelling: the 2 items in flight finish, the rest won’t go.")
        #expect(run.queueTitle(of: items[2]) == nil, "It won't go")
    }

    @Test func clockTitles() {
        #expect(ExtrasPushRun.clock(42) == "0:42")
        #expect(ExtrasPushRun.clock(372.9) == "6:12")
        #expect(ExtrasPushRun.clock(3725) == "1:02:05")
    }
}
#endif
