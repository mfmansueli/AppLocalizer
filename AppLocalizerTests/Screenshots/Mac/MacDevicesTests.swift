//
//  MacDevicesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Where Mac shows up: only for apps that run on Mac (a macOS version, Mac
/// captures, live Mac screenshots or a project that says so), after iPad
/// in the set, the Studio and the plan, and as a device the Look step can
/// add to the run.
@MainActor
@Suite("Mac devices")
struct MacDevicesTests {
    private static var withMac: ScreenshotsDocument {
        var document = ScreenshotsDebugDocuments.standard
        DebugEveryDevice.addMac(to: &document)
        return document
    }

    // MARK: - The set

    @Test func theSetHasAMacRowOnlyWithMacCaptures() {
        #expect(ScreenshotsDebugDocuments.standard.renderedDisplays == [.iPhone, .iPhoneDuo, .iPad])
        #expect(Self.withMac.renderedDisplays == [.iPhone, .iPhoneDuo, .iPad, .mac])
        var everyDevice = DebugEveryDevice.document
        DebugEveryDevice.addMac(to: &everyDevice)
        #expect(everyDevice.displays == [.iPhone, .iPhoneDuo, .iPad, .mac, .watch, .visionPro])
        #expect(Self.withMac.captures.hasCaptures(on: .mac))
        #expect(!ScreenshotsDebugDocuments.standard.captures.hasCaptures(on: .mac))
    }

    @Test func theMatrixListsMacAfterIPad() {
        let matrix = ScreenshotMatrixBuilder().build(ScreenshotsTestFixtures.snapshot(Self.withMac))
        #expect(matrix.hasMac)
        #expect(matrix.displays == [.iPhone, .iPhoneDuo, .iPad, .mac])
        #expect(matrix.cell(locale: "en-US", displayType: .mac, slot: 0) != nil)
        let plain = ScreenshotMatrixBuilder().build(ScreenshotsTestFixtures.snapshot(ScreenshotsDebugDocuments.standard))
        #expect(!plain.hasMac)
        #expect(!plain.displays.contains(.mac))
    }

    // MARK: - The Screenshots section

    @Test func aMacOSVersionMakesMacASetTemplatesRender() async {
        let plain = await StudioTestFixtures.screenshots(center: nil)
        #expect(!plain.runsOnMac)
        #expect(plain.renderedDisplays == [.iPhone, .iPhoneDuo, .iPad])

        let mac = await StudioTestFixtures.screenshots(center: nil, hasMacVersion: true)
        #expect(mac.runsOnMac)
        #expect(mac.renderedDisplays == [.iPhone, .iPhoneDuo, .iPad, .mac])
        #expect(mac.pixelSize(for: .mac) == PixelSize(width: 2880, height: 1800))
    }

    @Test func macCapturesAloneAreEnough() async {
        let model = await StudioTestFixtures.screenshots(center: nil, document: Self.withMac)
        #expect(model.runsOnMac)
        #expect(model.renderedDisplays.contains(.mac))
    }

    @Test func liveMacScreenshotsAreEnough() async {
        var live = StudioTestFixtures.live
        live.screenshotSets.append(ScreenshotPushTestFixtures.liveSet(.englishUS, display: .mac, count: 2))
        let model = await StudioTestFixtures.screenshots(center: nil, live: live)
        #expect(model.runsOnMac)
    }

    @Test func theDisplayMenuNoteGoesOnceMacIsRendered() async {
        let (plain, _) = await ScreenshotsTestFixtures.viewModel()
        #expect(plain.otherDisplayTypeNotes.map(\.0) == [.mac])
        let (mac, _) = await ScreenshotsTestFixtures.viewModel(Self.withMac)
        #expect(!mac.otherDisplayTypeNotes.contains { $0.0 == .mac })
    }

    // MARK: - The Studio and the plan

    @Test func theStudioShowsMacAfterIPad() async {
        let model = await StudioTestFixtures.screenshots(center: nil, hasMacVersion: true)
        #expect(model.studio.devices == [.iPhone, .iPhoneDuo, .iPad, .mac])
        #expect(model.studio.requiredReason(.mac) == "it has a macOS version")
        let plain = await StudioTestFixtures.screenshots(center: nil)
        #expect(!plain.studio.devices.contains(.mac))
        #expect(plain.studio.requiredReason(.mac) == nil)
    }

    @Test func thePlanSaysMacIsCapturedOnThisMac() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.plan)), hasMacVersion: true)
        var plan = StudioDebugRuns.plan
        plan.setPlans(.mac, true)
        #expect(model.studio.planDevices(plan) == [.iPhone, .iPhoneDuo, .iPad, .mac])
        #expect(model.studio.planDeviceDetail(.mac, plan: plan) == "2880 × 1800 · on this Mac · required: it has a macOS version")
    }

    @Test func autopilotPlansMacForAMacOSVersion() {
        let support = AutopilotSupport.make(
            profile: nil, declined: [], storeLocales: [], hasVisionVersion: false, hasMacVersion: true, live: LiveScreenshots()
        )
        #expect(support.devices == [.mac])
        let live = LiveScreenshots(screenshotSets: [ScreenshotPushTestFixtures.liveSet(.englishUS, display: .mac, count: 1)])
        let fromLive = AutopilotSupport.make(profile: nil, declined: [], storeLocales: [], hasVisionVersion: false, live: live)
        #expect(fromLive.devices == [.mac])
    }

    // MARK: - Look

    @Test func lookPreviewsMacAndAddsItToTheRun() async throws {
        let model = await StudioTestFixtures.screenshots(
            center: StudioTestFixtures.center(StudioDebugRuns.run(.plan)), document: Self.withMac
        )
        let studio = model.studio
        let plan = try #require(studio.run?.plan)
        #expect(studio.templatePreviewDevices(plan) == [.iPhone, .iPad, .iPhoneDuo, .mac])
        #expect(!studio.templatePreviewIsInRun(.mac, plan: plan))
        studio.addTemplatePreviewDevice(.mac)
        let added = try #require(studio.run?.plan)
        #expect(added.displayTypes.contains(.mac))
        #expect(studio.templatePreviewIsInRun(.mac, plan: added))
        #expect(studio.templatePreviewDevice(added) == .mac, "The preview stays on Mac")
    }
}
#endif
