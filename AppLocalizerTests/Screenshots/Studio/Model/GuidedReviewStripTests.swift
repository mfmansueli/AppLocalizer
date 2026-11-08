//
//  GuidedReviewStripTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review & push's screenshots: a device switch for every device in the
/// run in the App Store's order, languages by name, the line under the
/// strip, and a language switch in the viewer that keeps the screen.
@MainActor
@Suite("Guided review strip")
struct GuidedReviewStripTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    // MARK: - Names

    @Test func languagesSwitchByName() {
        let titles = GuidedPreviewLocales.titles(["en-US", "de-DE", "ja", "ar-SA"])
        #expect(titles == ["en-US": "English", "de-DE": "German", "ja": "Japanese", "ar-SA": "Arabic"])
    }

    @Test func twoThatReadTheSameKeepTheirWholeNames() throws {
        let titles = GuidedPreviewLocales.titles(["en-US", "es-ES", "es-MX"])
        #expect(titles["en-US"] == "English")
        let spain = try #require(StoreLocaleCatalog.locale(code: "es-ES")?.name)
        let mexico = try #require(StoreLocaleCatalog.locale(code: "es-MX")?.name)
        #expect(titles["es-ES"] == spain)
        #expect(titles["es-MX"] == mexico)
        #expect(spain != mexico)
        #expect(GuidedPreviewLocales.title(of: "ja", among: ["en-US"]) == "Japanese")
    }

    // MARK: - The line under the strip

    @Test func theLineSaysTheSizeAndWhatTheStoreDoes() {
        #expect(GuidedReviewDeviceNote.line(.iPhone, size: PixelSize(width: 1320, height: 2868), app: "Lumen", count: 5)
            == "iPhone 6.9″ · 1320 × 2868 · the App Store scales it for smaller iPhones · click one to see it larger")
        #expect(GuidedReviewDeviceNote.line(.mac, size: PixelSize(width: 2880, height: 1800), app: "Lumen", count: 5)
            == "Mac · 2880 × 1800 · Lumen’s Mac window on a MacBook · click one to see it larger")
        #expect(GuidedReviewDeviceNote.line(.iPhoneDuo, size: PixelSize(width: 2007, height: 2853), app: "Lumen", count: 5)
            == "iPhone Duo · inner display · 2007 × 2853 · click one to see it larger")
        #expect(GuidedReviewDeviceNote.line(.iPad, size: PixelSize(width: 2752, height: 2064), app: "Lumen", count: 5).contains(" · landscape · "))
        #expect(GuidedReviewDeviceNote.line(.watch, size: nil, app: "Lumen", count: 3).contains("the bare screen; Apple adds the frame"))
        #expect(GuidedReviewDeviceNote.line(.visionPro, size: nil, app: "Lumen", count: 3).contains(" · 3 screenshots · "))
    }

    // MARK: - Devices and the viewer

    @Test func everyDeviceInTheRunInTheStoresOrder() async {
        var run = StudioDebugGuided.ready(approved: [])
        run.plan.setPlans(.watch, true)
        run.plan.setPlans(.visionPro, true)
        run.plan.setPlans(.mac, true)
        let center = StudioTestFixtures.center(run)
        let model = await StudioTestFixtures.screenshots(center: center)
        #expect(model.studio.guidedReviewDevices == [.iPhone, .iPad, .mac, .visionPro, .watch])
    }

    @Test func theViewerSwitchesLanguageAndKeepsTheScreen() async throws {
        let run = StudioDebugRuns.run(.ready)
        let center = StudioTestFixtures.center(run)
        let model = await StudioTestFixtures.screenshots(center: center)
        let studio = model.studio
        let shots = studio.guidedNewShots(locale: "en-US", device: .iPhone)
        try #require(shots.count > 2)
        studio.openGuidedShots(shots, locale: "en-US", device: .iPhone, at: 2)
        #expect(studio.viewerReviewDevice == .iPhone)
        #expect(studio.viewerReviewLocales.first == "en-US")
        #expect(studio.viewerReviewLocales.contains("de-DE"))

        studio.setViewerReviewLocale("de-DE")
        let viewer = try #require(studio.viewer)
        #expect(viewer.index == 2, "The same screen")
        #expect(viewer.current.subtitle.hasPrefix(StoreLocaleCatalog.locale(code: "de-DE")?.name ?? "German"))
        #expect(studio.guidedReviewLocale == "de-DE", "The strip behind follows")

        studio.closeViewer()
        #expect(studio.viewerReviewDevice == nil)
    }

    @Test func aLanguageFromTheMenuJoinsTheViewersSwitch() async {
        let run = StudioDebugRuns.run(.ready)
        let center = StudioTestFixtures.center(run)
        let model = await StudioTestFixtures.screenshots(center: center)
        let studio = model.studio
        let menu = run.plan.localeCodes.first { !studio.guidedReviewLocales.contains($0) }
        guard let menu else { return }
        studio.guided.reviewLocale = menu
        #expect(studio.viewerReviewLocales.last == menu)
    }
}
#endif
