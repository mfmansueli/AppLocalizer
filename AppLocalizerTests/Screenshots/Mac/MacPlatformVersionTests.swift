//
//  MacPlatformVersionTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Mac screenshots go in the app's macOS version: its localizations are
/// App Store Connect's own, read apart from the iOS version's, and without
/// them the Mac set waits. When the version open is the macOS one, its own
/// localizations take them.
@MainActor
@Suite("Mac · macOS version")
struct MacPlatformVersionTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    private static var document: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        DebugEveryDevice.addMac(to: &document)
        return document
    }

    private static func context(mac: Bool) -> ScreenshotsContext {
        var context = Fixtures.context()
        context.hasMacVersion = true
        if mac {
            for (locale, _) in context.localizations { context.macLocalizations[locale] = "mac-loc-\(locale.code)" }
        }
        return context
    }

    private static func version(_ id: String, _ string: String, platform: String, editable: Bool, day: Int) -> StorePageVersion {
        StorePageVersion(
            id: id,
            listingVersion: ListingVersion(string, state: editable ? .prepareForSubmission : .readyForDistribution),
            platform: platform,
            createdDate: StudioDebugRuns.date(day: day, month: 10)
        )
    }

    // MARK: - The version that opens

    /// Bruma: iPhone sets sent to a newer macOS version came back "Display
    /// Type Not Allowed!".
    @Test func theIOSVersionOpensEvenWhenTheMacOSOneIsNewer() {
        let ios = Self.version("ios-10", "1.0", platform: "IOS", editable: true, day: 1)
        let mac = Self.version("mac-10", "1.0", platform: "MAC_OS", editable: true, day: 2)
        let versions = StorePageVersion.pickerVersions(from: [ios, mac])
        #expect(versions.map(\.id) == ["mac-10", "ios-10"], "Both stay in the picker")
        #expect(StorePageVersion.preferred(in: versions)?.id == "ios-10")
    }

    @Test func aLiveIOSVersionOpensBeforeAnEditableMacOSOne() {
        let ios = Self.version("ios-10", "1.0", platform: "IOS", editable: false, day: 1)
        let mac = Self.version("mac-11", "1.1", platform: "MAC_OS", editable: true, day: 2)
        #expect(StorePageVersion.preferred(in: [mac, ios])?.id == "ios-10")
    }

    @Test func aMacOnlyAppOpensItsMacOSVersion() {
        let mac = Self.version("mac-10", "1.0", platform: "MAC_OS", editable: true, day: 2)
        #expect(StorePageVersion.preferred(in: [mac])?.id == "mac-10")
    }

    @Test func eachPlatformKeepsItsLiveVersion() {
        let ios = Self.version("ios-10", "1.0", platform: "IOS", editable: false, day: 1)
        let older = Self.version("ios-09", "0.9", platform: "IOS", editable: false, day: 0)
        let mac = Self.version("mac-10", "1.0", platform: "MAC_OS", editable: false, day: 2)
        let versions = StorePageVersion.pickerVersions(from: [older, ios, mac])
        #expect(versions.map(\.id) == ["mac-10", "ios-10"])
        #expect(StorePageVersion.preferred(in: versions)?.id == "ios-10")
    }

    // MARK: - Localizations

    @Test func macGoesInTheMacOSLocalizations() throws {
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        let context = Self.context(mac: true)
        #expect(context.localizationID(for: german, displayType: .mac) == "mac-loc-de-DE")
        #expect(context.localizationID(for: german, displayType: .iPad) == "loc-de-DE")
        #expect(Self.context(mac: false).localizationID(for: german, displayType: .mac) == nil, "Not the iOS version's")
    }

    @Test func theMacOSVersionOpenTakesItsOwn() throws {
        let german = try #require(StoreLocaleCatalog.locale(code: "de-DE"))
        var context = Self.context(mac: false)
        context.isMacVersion = true
        #expect(context.localizationID(for: german, displayType: .mac) == "loc-de-DE")
    }

    @Test func theContextKnowsTheAppHasAMacOSVersion() {
        var content = DebugStorePageContent.lumen(versionID: nil)
        #expect(!ScreenshotsContext(content: content).hasMacVersion)
        content.versions.append(Self.version("mac-14", content.version.versionString, platform: "MAC_OS", editable: true, day: 2))
        let context = ScreenshotsContext(content: content)
        #expect(context.hasMacVersion)
        #expect(!context.isMacVersion, "The iOS version is open")

        var macOpen = content
        macOpen.version = Self.version("mac-14", "1.4", platform: "MAC_OS", editable: true, day: 2)
        #expect(ScreenshotsContext(content: macOpen).isMacVersion)
    }

    @Test func theMacOSVersionMatchingTheVersionIsRead() async {
        var content = DebugStorePageContent.lumen(versionID: nil)
        let iOS = content.version
        content.versions = [
            iOS,
            Self.version("mac-old", "1.3", platform: "MAC_OS", editable: false, day: 1),
            Self.version("mac-14", iOS.versionString, platform: "MAC_OS", editable: true, day: 2),
            Self.version("vision-14", iOS.versionString, platform: "VISION_OS", editable: true, day: 2),
        ]
        #expect(ScreenshotsContext.macVersionID(in: content) == "mac-14")

        var context = ScreenshotsContext(content: content)
        var asked: [String] = []
        await context.readPlatformLocalizations(in: content) { id in
            asked.append(id)
            var other = DebugStorePageContent.lumen(versionID: nil)
            other.ids.versionLocalizations = [.german: id == "mac-14" ? "mac-loc-de" : "vision-loc-de"]
            return other
        }
        #expect(asked == ["vision-14", "mac-14"])
        #expect(context.macLocalizations == [.german: "mac-loc-de"])
        #expect(context.visionLocalizations == [.german: "vision-loc-de"])
    }

    @Test func withTheMacOSVersionOpenNothingMoreIsRead() async {
        var content = DebugStorePageContent.lumen(versionID: nil)
        content.version = Self.version("mac-14", "1.4", platform: "MAC_OS", editable: true, day: 2)
        content.versions = [content.version]
        var context = ScreenshotsContext(content: content)
        await context.readMacLocalizations(in: content) { _ in
            Issue.record("The open version's localizations are already there")
            return content
        }
        #expect(context.macLocalizations.isEmpty)
    }

    // MARK: - Push

    @Test func macSetsArePushedToTheMacOSVersion() throws {
        let plan = ScreenshotPushPlanner().plan(Fixtures.input(document: Self.document, context: Self.context(mac: true)))
        let mac = plan.groups.filter { $0.displayType == .mac }
        #expect(!mac.isEmpty)
        #expect(mac.allSatisfy { $0.localizationID == "mac-loc-\($0.locale.code)" })
        let english = try #require(mac.first { $0.locale.code == "en-US" })
        #expect(english.items.allSatisfy { $0.cell.displayType == .mac })
        var seen: [ScreenshotDisplayType] = []
        for display in plan.groups.map(\.displayType) where seen.last != display { seen.append(display) }
        #expect(seen == [.iPhone, .iPad, .mac], "Mac after iPad")
    }

    @Test func withoutTheMacOSLocalizationsMacWaits() {
        let plan = ScreenshotPushPlanner().plan(Fixtures.input(document: Self.document, context: Self.context(mac: false)))
        #expect(!plan.groups.contains { $0.displayType == .mac })
        #expect(plan.missingLocalizations.contains { $0.cell.displayType == .mac })
        #expect(plan.groups.contains { $0.displayType == .iPhone })
    }

    @Test func liveMacSetsComeFromTheMacOSLocalizations() async throws {
        let services = StudioTestServices()
        let phone = Fixtures.liveSet(.englishUS, display: .iPhone, count: 5)
        let mac = Fixtures.liveSet(.englishUS, display: .mac, count: 3)
        services.liveForLocalizations = { localizations in
            localizations.values.contains { $0.hasPrefix("mac-") }
                ? LiveScreenshots(screenshotSets: [mac, phone])
                : LiveScreenshots(screenshotSets: [phone])
        }
        let live = try await services.liveScreenshots(for: ScreenshotsTestFixtures.app, context: Self.context(mac: true))
        #expect(live.screenshotSets.map(\.displayType) == [.iPhone, .mac], "Only Mac is taken from macOS")

        let without = try await services.liveScreenshots(for: ScreenshotsTestFixtures.app, context: Self.context(mac: false))
        #expect(without.screenshotSets.map(\.displayType) == [.iPhone])
    }

    // MARK: - A version that can't change

    private func plan(_ context: ScreenshotsContext) -> ScreenshotPushPlan {
        ScreenshotPushPlanner().plan(Fixtures.input(document: Self.document, context: context))
    }

    @Test func aLiveIOSVersionStillLetsMacScreenshotsGo() {
        var context = Self.context(mac: true)
        context.version = ScreenshotsTestFixtures.liveVersion
        context.macVersionIsEditable = true
        let plan = plan(context)
        #expect(plan.blockedReason == nil)
        #expect(!plan.groups.isEmpty)
        #expect(plan.groups.allSatisfy { $0.displayType == .mac })
        #expect(plan.excluded.contains { $0.failedCheck?.contains("1.3") == true })
    }

    @Test func aLiveMacVersionLeavesOnlyMacOut() {
        var context = Self.context(mac: true)
        context.macVersionIsEditable = false
        let plan = plan(context)
        #expect(plan.blockedReason == nil)
        #expect(!plan.groups.isEmpty)
        #expect(plan.groups.allSatisfy { $0.displayType != .mac })
        #expect(plan.excluded.contains { $0.failedCheck?.contains("macOS version is live") == true })
    }

    @Test func everyVersionLiveBlocksThePush() {
        var context = Self.context(mac: true)
        context.version = ScreenshotsTestFixtures.liveVersion
        context.macVersionIsEditable = false
        #expect(plan(context).blockedReason?.contains("1.3") == true)
    }

    // MARK: - The macOS version that goes with the iOS one

    private static func content(mac versions: [StorePageVersion]) -> StorePageContent {
        var content = DebugStorePageContent.lumen(versionID: "ios-14")
        let iOS = version("ios-14", "1.4", platform: "IOS", editable: true, day: 9)
        content.version = iOS
        content.versions = [iOS] + versions
        return content
    }

    private static func macVersionID(_ versions: [StorePageVersion]) -> String? {
        ScreenshotsContext.versionID(platform: "MAC_OS", in: content(mac: versions))
    }

    @Test func theMacVersionPrefersEditableWithTheSameNumber() {
        let live = Self.version("mac-live", "1.4", platform: "MAC_OS", editable: false, day: 8)
        let newer = Self.version("mac-15", "1.5", platform: "MAC_OS", editable: true, day: 7)
        let same = Self.version("mac-14", "1.4", platform: "MAC_OS", editable: true, day: 6)
        #expect(Self.macVersionID([live, newer, same]) == "mac-14")
        #expect(Self.macVersionID([live, newer]) == "mac-15", "Anything editable beats a live one with the same number")
        #expect(Self.macVersionID([live]) == "mac-live")
    }
}
#endif
