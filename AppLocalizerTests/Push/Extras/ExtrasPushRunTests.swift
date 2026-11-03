//
//  ExtrasPushRunTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// One extras push against a fake asset library: each file is reserved,
/// uploaded, committed and processed before anything is placed; artwork
/// takes its slot's place, App Previews replace what they name and go
/// first, and failures say why in Apple's words.
@MainActor
@Suite("ExtrasPushRun")
struct ExtrasPushRunTests {
    private typealias Fixtures = ExtrasPushFixtures

    private let header = ExtrasPushKind.productPageHeader
    private let search = ExtrasPushKind.searchResults
    private let preview = ExtrasPushKind.appPreviewPlacement

    @Test func artworkTakesThePlaceOfTheHeaderInItsSlot() async {
        let live = [Fixtures.localizationID: [Fixtures.live("p-old", header, group: Fixtures.headerGroup)]]
        let library = FakeAssetLibrary(placements: live)
        let item = Fixtures.header()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        let size = Fixtures.data(for: item).count
        #expect(run.status(of: item) == .done(assetID: "image-1", placementIDs: ["p-2"]))
        #expect(library.log == [
            "ref-data", "library app-1", "reserve image de-DE-header.png \(size) CREATIVE_ASSETS", "upload image-1 1", "upload image-1 2",
            "commit image-1", "state image-1", "state image-1",
            "list loc-de \(header) \(Fixtures.headerGroup)", "delete p-old", "place image-1 \(header) \(Fixtures.headerGroup) loc-de",
        ])
        #expect(library.uploaded("image-1") == Fixtures.data(for: item))
        #expect(library.placements(on: Fixtures.localizationID).map(\.assetID) == ["image-1"])
        #expect(run.doneCount == 1)
        #expect(run.title == "1 extra pushed")
    }

    @Test func aWideImageIsUploadedOnceAndPlacedUnderBothTypes() async {
        let library = FakeAssetLibrary()
        let item = Fixtures.wide()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item) == .done(assetID: "image-1", placementIDs: ["p-2", "p-3"]))
        #expect(library.log.count { $0.hasPrefix("reserve") } == 1)
        #expect(library.log.filter { $0.hasPrefix("place") } == [
            "place image-1 \(header) \(Fixtures.headerGroup) loc-de", "place image-1 \(search) \(Fixtures.searchGroup) loc-de",
        ])
        #expect(!library.log.contains { $0.hasPrefix("delete") })
    }

    /// A header's motion loop is reserved as a video, its first frame the
    /// poster, and takes the header's place like the image.
    @Test func aMotionLoopIsAVideoPlacedLikeTheImage() async {
        let live = [Fixtures.localizationID: [Fixtures.live("p-old", header, group: Fixtures.headerGroup)]]
        // The header takes a video of its size too.
        let json = AssetLibraryRefDataSample.json
            .replacingOccurrences(of: "\"videoSpecs\": [", with: """
            "videoSpecs": [{"specId": "spec-header-video", "dimensions": {"minWidth": 3840, "maxWidth": 3840, "minHeight": 1646, \
            "maxHeight": 1646}, "compatiblePlacementTypes": ["PRODUCT_PAGE_HEADER_ASSET"]},
            """)
            .replacingOccurrences(of: "\"specs\": [\"spec-header\", \"spec-wide\"]", with: "\"specs\": [\"spec-header\", \"spec-wide\", \"spec-header-video\"]")
        var script = FakeAssetLibrary.Script()
        script.refData = (try? AssetLibraryRefData(json: Data(json.utf8))) ?? AssetLibraryRefData()
        let library = FakeAssetLibrary(script, placements: live)
        var item = Fixtures.header()
        item.kind = .motionArtwork(placementTypes: [header])
        item.fileName = "de-DE-header.mov"
        item.fileURL = URL(fileURLWithPath: "/tmp/extras/de-DE-header-loop.mov")
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        let size = Fixtures.data(for: item).count
        #expect(run.status(of: item) == .done(assetID: "video-1", placementIDs: ["p-2"]))
        #expect(library.log.contains("reserve video de-DE-header.mov \(size) CREATIVE_ASSETS poster 00:00:00:00"))
        #expect(library.log.contains("delete p-old"))
        #expect(library.log.contains("place video-1 \(header) \(Fixtures.headerGroup) loc-de"))
        #expect(library.uploaded("video-1") == Fixtures.data(for: item))
    }

    @Test func aSizeNoGroupTakesFailsBeforeAnythingIsUploaded() async {
        let library = FakeAssetLibrary()
        let item = Fixtures.header(size: PixelSize(width: 3000, height: 1286))
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item) == .failed(
            "App Store Connect doesn’t take a 3000 × 1286 image for the product page header; it takes 3840 × 1646 or 5244 × 2950. "
                + "Nothing was uploaded."
        ))
        #expect(library.log == ["ref-data"])
    }

    @Test func anAppPreviewIsRefusedWhenItsGroupHasThree() async {
        let library = FakeAssetLibrary(placements: Fixtures.livePreviews(["p-a", "p-b", "p-c"]))
        let item = Fixtures.preview()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item).failureReason == "\(Fixtures.iPhoneGroup) already has 3 App Previews, the most it holds, and this one "
            + "replaces none of them. Nothing was uploaded.")
        #expect(library.log == ["ref-data", "list loc-de \(preview) \(Fixtures.iPhoneGroup)"])
        #expect(library.placements(on: Fixtures.localizationID).map(\.id) == ["p-a", "p-b", "p-c"])
    }

    @Test func anAppPreviewInAFullGroupReplacesTheOneItNamesAndGoesFirst() async {
        let library = FakeAssetLibrary(placements: Fixtures.livePreviews(["p-a", "p-b", "p-c"]))
        let item = Fixtures.preview(replacing: ["p-b"])
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item) == .done(assetID: "video-1", placementIDs: ["p-2"]))
        let reserve = library.log.first { $0.hasPrefix("reserve") }
        #expect(reserve?.hasSuffix("APP_SCREENSHOTS_AND_PREVIEWS poster 00:00:05:00") == true)
        #expect(Array(library.log.suffix(4)) == [
            "list loc-de \(preview) \(Fixtures.iPhoneGroup)", "delete p-b", "place video-1 \(preview) \(Fixtures.iPhoneGroup) loc-de",
            "order \(Fixtures.iPhoneGroup) p-2,p-a,p-c",
        ])
        #expect(library.placements(on: Fixtures.localizationID).map(\.id) == ["p-2", "p-a", "p-c"])
    }

    @Test func withRoomTheNewPreviewIsPlacedBeforeTheOneItReplacesIsTakenOff() async {
        let library = FakeAssetLibrary(placements: Fixtures.livePreviews(["p-a", "p-b"]))
        let item = Fixtures.preview(replacing: ["p-a", "p-gone"])
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item).isDone)
        #expect(Array(library.log.suffix(3)) == [
            "place video-1 \(preview) \(Fixtures.iPhoneGroup) loc-de", "delete p-a", "order \(Fixtures.iPhoneGroup) p-2,p-b",
        ])
    }

    @Test func failedProcessingSurfacesApplesStateDetails() async {
        var script = FakeAssetLibrary.Script()
        script.processingFailures = ["de-DE-header": AssetLibraryStateDetail(code: "IMAGE_INCORRECT_DIMENSIONS", message: "The image is 3000 × 1286")]
        let library = FakeAssetLibrary(script)
        let item = Fixtures.header()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item) == .failed(
            "Apple couldn’t process the file (IMAGE_INCORRECT_DIMENSIONS — The image is 3000 × 1286). Nothing was placed."
        ))
        #expect(!library.log.contains { $0.hasPrefix("list") || $0.hasPrefix("place") })
        #expect(run.failures.map(\.item) == [item])

        // Apple refused that file, so a retry uploads it again.
        run.retryFailed()
        await run.waitUntilFinished()
        #expect(run.status(of: item).isDone)
        #expect(library.log.count { $0.hasPrefix("reserve") } == 2)
    }

    @Test func retryFailedSendsOnlyTheFailedAndReusesTheirUpload() async {
        var script = FakeAssetLibrary.Script()
        script.refusedPlacements = ["de-DE-header"]
        let library = FakeAssetLibrary(script)
        let header = Fixtures.header()
        let preview = Fixtures.preview()
        let run = await Fixtures.push([header, preview], environment: Fixtures.environment(library))

        #expect(run.status(of: header) == .failed("STATE_ERROR.INVALID_STATE — The version can’t be edited."))
        #expect(run.status(of: preview).isDone)
        #expect(run.title == "1 of 2 extras pushed")
        let before = library.log.count

        run.retryFailed()
        await run.waitUntilFinished()
        #expect(run.status(of: header) == .done(assetID: "image-1", placementIDs: ["p-4"]))
        #expect(run.status(of: preview).isDone)
        #expect(Array(library.log.dropFirst(before)) == [
            "list loc-de \(self.header) \(Fixtures.headerGroup)", "place image-1 \(self.header) \(Fixtures.headerGroup) loc-de",
        ])
        #expect(run.title == "All 2 extras pushed")
    }

    @Test func aRefusedReplacementPutsTheOldHeaderBack() async {
        var script = FakeAssetLibrary.Script()
        script.refusedPlacements = ["de-DE-header"]
        let live = [Fixtures.localizationID: [Fixtures.live("p-old", header, group: Fixtures.headerGroup)]]
        let library = FakeAssetLibrary(script, placements: live)
        let item = Fixtures.header()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library))

        #expect(run.status(of: item) == .failed(
            "Couldn’t place it (STATE_ERROR.INVALID_STATE — The version can’t be edited.). What was there before was put back."
        ))
        #expect(Array(library.log.suffix(3)) == [
            "delete p-old", "place image-1 \(header) \(Fixtures.headerGroup) loc-de", "place asset-p-old \(header) \(Fixtures.headerGroup) loc-de",
        ])
        #expect(library.placements(on: Fixtures.localizationID).map(\.assetID) == ["asset-p-old"])
    }

    @Test func processingThatOutlastsTheWaitIsPickedUpByARetry() async {
        var script = FakeAssetLibrary.Script()
        script.stuck = ["de-DE-header"]
        let library = FakeAssetLibrary(script)
        let item = Fixtures.header()
        let run = await Fixtures.push([item], environment: Fixtures.environment(library, processingTimeout: .seconds(2)))

        #expect(run.status(of: item) == .failed("Apple was still processing the file. It’s uploaded; Retry Failed places it once it’s ready."))
        #expect(library.log.count { $0 == "state image-1" } == 3)
        let before = library.log.count

        library.finishProcessing("de-DE-header")
        run.retryFailed()
        await run.waitUntilFinished()
        #expect(run.status(of: item).isDone)
        #expect(Array(library.log.dropFirst(before)) == [
            "state image-1", "list loc-de \(header) \(Fixtures.headerGroup)", "place image-1 \(header) \(Fixtures.headerGroup) loc-de",
        ])
    }

    @Test func cancelRemainingLetsTheItemInFlightFinish() async {
        let holder = ExtrasPushRunHolder()
        let library = FakeAssetLibrary(onReserve: { await holder.cancel() })
        let header = Fixtures.header()
        let preview = Fixtures.preview()
        let run = ExtrasPushRun(items: [header, preview], environment: Fixtures.environment(library))
        holder.run = run
        run.start()
        await run.waitUntilFinished()

        #expect(run.status(of: header).isDone)
        #expect(run.status(of: preview) == .cancelled)
        #expect(!library.log.contains { $0.hasPrefix("reserve video") })
        #expect(run.phase == .finished)
        #expect(!run.isCancelling)
    }

    @Test func offlineStopsTheRest() async {
        var script = FakeAssetLibrary.Script()
        script.offline = ["de-DE-header"]
        let library = FakeAssetLibrary(script)
        let header = Fixtures.header()
        let preview = Fixtures.preview()
        let run = await Fixtures.push([header, preview], environment: Fixtures.environment(library))

        #expect(run.status(of: header) == .failed("Not sent · offline"))
        #expect(run.status(of: preview) == .failed("Not sent · offline"))
        #expect(library.log.last?.hasPrefix("reserve image") == true)
        #expect(run.failedCount == 2)
    }

    @Test func theLibraryAndReferenceDataAreReadOnce() async {
        let library = FakeAssetLibrary()
        let run = await Fixtures.push([Fixtures.header(), Fixtures.wide(), Fixtures.preview()], environment: Fixtures.environment(library))

        #expect(run.doneCount == 3)
        #expect(library.log.count { $0 == "ref-data" } == 1)
        #expect(library.log.count { $0 == "library app-1" } == 1)
    }

    @Test func aUsedUpHourPausesThenGoesOn() async {
        var script = FakeAssetLibrary.Script()
        script.rateLimitedOnce = true
        let library = FakeAssetLibrary(script)
        let clock = ScreenshotPushTestClock()
        let environment = Fixtures.environment(library, clock: clock)
        let nextHour = environment.rate.nextHour()
        let item = Fixtures.header()
        let run = await Fixtures.push([item], environment: environment)

        #expect(run.status(of: item).isDone)
        #expect(Array(library.log.prefix(2)) == ["429", "ref-data"])
        #expect(clock.now >= nextHour)
        #expect(run.pausedUntil == nil)
    }

    @Test func statusTitles() {
        #expect(ExtrasPushStatus.waiting.title == "Waiting")
        #expect(ExtrasPushStatus.uploading(0.426).title == "Uploading 42%")
        #expect(ExtrasPushStatus.processing.title == "Processing")
        #expect(ExtrasPushStatus.placing.title == "Placing")
        #expect(ExtrasPushStatus.done(assetID: "a", placementIDs: []).title == "Done")
        #expect(ExtrasPushStatus.failed("Why.").title == "Failed")
        #expect(ExtrasPushStatus.failed("Why.").failureReason == "Why.")
        #expect(ExtrasPushStatus.cancelled.isFinished)
        #expect(!ExtrasPushStatus.processing.isFinished)
    }
}
#endif
