//
//  ScreenshotPushDevicesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Pushing Apple Watch and Apple Vision Pro screenshots: the watch's go in
/// the iOS version's localizations, Apple Vision Pro's in the visionOS
/// version's, which App Store Connect keeps apart; without those they
/// wait.
@MainActor
@Suite("Screenshot push · Apple Watch and Apple Vision Pro")
struct ScreenshotPushDevicesTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    private static func context(vision: Bool) -> ScreenshotsContext {
        var context = Fixtures.context()
        if vision {
            for (locale, _) in context.localizations { context.visionLocalizations[locale] = "vision-loc-\(locale.code)" }
        }
        return context
    }

    private static func plan(vision: Bool) -> ScreenshotPushPlan {
        ScreenshotPushPlanner().plan(Fixtures.input(document: DebugEveryDevice.document, live: DebugEveryDevice.live, context: context(vision: vision)))
    }

    @Test func watchScreenshotsGoInTheIOSLocalizations() throws {
        let plan = Self.plan(vision: true)
        let watch = plan.groups.filter { $0.displayType == .watch }
        #expect(watch.count == ScreenshotsSampleData.scope.count)
        let german = try #require(watch.first { $0.locale.code == "de-DE" })
        #expect(german.localizationID == "loc-de-DE")
        #expect(german.items.count == 4)
        let english = try #require(watch.first { $0.locale.code == "en-US" })
        #expect(english.liveSet?.screenshots.count == 2, "The two hand-uploaded captures are replaced")
    }

    @Test func visionProScreenshotsGoInTheVisionOSLocalizations() {
        let plan = Self.plan(vision: true)
        let vision = plan.groups.filter { $0.displayType == .visionPro }
        #expect(vision.count == ScreenshotsSampleData.scope.count)
        #expect(vision.allSatisfy { $0.localizationID == "vision-loc-\($0.locale.code)" })
        // German's "Search" caption overflows in the sample, so its window waits.
        #expect(vision.map(\.items.count) == vision.map { $0.locale.code == "de-DE" ? 2 : 3 })
    }

    @Test func withoutTheVisionOSLocalizationsVisionProWaits() {
        let plan = Self.plan(vision: false)
        #expect(!plan.groups.contains { $0.displayType == .visionPro })
        let waiting = plan.missingLocalizations.filter { $0.cell.displayType == .visionPro }
        #expect(waiting.count == ScreenshotsSampleData.scope.count * 3 - 1, "All but German's overflowing window")
        #expect(plan.groups.contains { $0.displayType == .watch })
    }

    /// Each image is named after its device's own screen: the watch's
    /// "Mood check-in", not the iPhone slot's "Today". Alba's iPhone Duo
    /// listed "Today's phrase · cover" as "2 Animated scenes", and its
    /// last four as "Slot 7"…
    @Test func imagesAreNamedAfterTheirDevicesOwnScreens() throws {
        let plan = Self.plan(vision: true)
        let watch = try #require(plan.groups.first { $0.displayType == .watch && $0.locale.code == "de-DE" })
        #expect(watch.items.map(\.slotName) == DebugEveryDevice.watchScreens.map(\.name))
        let iPhone = try #require(plan.groups.first { $0.displayType == .iPhone })
        #expect(iPhone.items.allSatisfy { ScreenshotsSampleData.slotNames.contains($0.slotName) })

        var document = ScreenshotsDebugDocuments.standard
        document.setScreens([DeviceScreen(name: "Today · inner", captionSlot: 0), DeviceScreen(name: "Today · cover", captionSlot: 0)], on: .iPhoneDuo)
        #expect(document.slotName(1, on: .iPhoneDuo) == "Today · cover")
        #expect(document.slotName(1, on: .iPhone) == "Week")
    }

    @Test func setsGoIPhoneIPadWatchThenVisionPro() {
        let order = Self.plan(vision: true).groups.map(\.displayType)
        var seen: [ScreenshotDisplayType] = []
        for display in order where seen.last != display { seen.append(display) }
        #expect(seen == [.iPhone, .iPad, .watch, .visionPro])
    }

    // MARK: - Context

    @Test func eachDeviceHasItsLocalization() throws {
        let context = Self.context(vision: true)
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        #expect(context.localizationID(for: german, displayType: .iPhone) == "loc-de-DE")
        #expect(context.localizationID(for: german, displayType: .watch) == "loc-de-DE")
        #expect(context.localizationID(for: german, displayType: .visionPro) == "vision-loc-de-DE")
        #expect(Self.context(vision: false).localizationID(for: german, displayType: .visionPro) == nil)
    }

    @Test func theVisionOSVersionMatchingTheVersionIsRead() async {
        var content = DebugStorePageContent.lumen(versionID: nil)
        let iOS = content.version
        content.versions = [
            iOS,
            Self.version("vision-old", "1.3", platform: "VISION_OS", editable: false, day: 1),
            Self.version("vision-14", iOS.versionString, platform: "VISION_OS", editable: true, day: 2),
            Self.version("vision-next", "1.5", platform: "VISION_OS", editable: true, day: 3),
        ]
        #expect(ScreenshotsContext.visionVersionID(in: content) == "vision-14")

        var context = ScreenshotsContext(content: content)
        #expect(context.hasVisionVersion)
        var asked: [String] = []
        await context.readVisionLocalizations(in: content) { id in
            asked.append(id)
            var vision = DebugStorePageContent.lumen(versionID: nil)
            vision.ids.versionLocalizations = [.german: "vision-loc-de"]
            return vision
        }
        #expect(asked == ["vision-14"])
        #expect(context.visionLocalizations == [.german: "vision-loc-de"])
    }

    @Test func withoutAVisionOSVersionNothingMoreIsRead() async {
        let content = DebugStorePageContent.lumen(versionID: nil)
        #expect(ScreenshotsContext.visionVersionID(in: content) == nil)
        var context = ScreenshotsContext(content: content)
        await context.readVisionLocalizations(in: content) { _ in
            Issue.record("Nothing to read")
            return content
        }
        #expect(context.visionLocalizations.isEmpty)
    }

    // MARK: - Live

    @Test func liveVisionProSetsComeFromTheVisionOSLocalizations() async throws {
        let services = StudioTestServices()
        let phone = Fixtures.liveSet(.englishUS, display: .iPhone, count: 5)
        let vision = Fixtures.liveSet(.englishUS, display: .visionPro, count: 2)
        services.liveForLocalizations = { localizations in
            localizations.values.contains { $0.hasPrefix("vision-") }
                ? LiveScreenshots(screenshotSets: [vision, phone])
                : LiveScreenshots(screenshotSets: [phone])
        }
        let live = try await services.liveScreenshots(for: ScreenshotsTestFixtures.app, context: Self.context(vision: true))
        #expect(live.screenshotSets.map(\.displayType) == [.iPhone, .visionPro], "Only Apple Vision Pro is taken from visionOS")

        let without = try await services.liveScreenshots(for: ScreenshotsTestFixtures.app, context: Self.context(vision: false))
        #expect(without.screenshotSets.map(\.displayType) == [.iPhone])
    }

    private static func version(_ id: String, _ string: String, platform: String, editable: Bool, day: Int) -> StorePageVersion {
        StorePageVersion(
            id: id,
            listingVersion: ListingVersion(string, state: editable ? .prepareForSubmission : .readyForDistribution),
            platform: platform,
            createdDate: StudioDebugRuns.date(day: day, month: 10)
        )
    }
}
#endif
