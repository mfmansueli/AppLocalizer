//
//  ScreenshotPushTestFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Plans, sets and push environments for the screenshot push tests, on
/// Lumen Journal's sample screenshots.
@MainActor
enum ScreenshotPushTestFixtures {
    static let app = ScreenshotsTestFixtures.app
    static let slotNames = ScreenshotsSampleData.slotNames
    /// What every test image uploads.
    static let png = Data((0..<1000).map { UInt8($0 % 251) })

    /// Version 1.4 with a localization for every locale in the sample
    /// scope but `missing`.
    static func context(version: ScreenshotsVersion = ScreenshotsTestFixtures.editableVersion, missing: Set<String> = []) -> ScreenshotsContext {
        var localizations: [StoreLocale: String] = [:]
        for code in ScreenshotsSampleData.scope where !missing.contains(code) {
            if let locale = StoreLocaleCatalog.locale(code: code) { localizations[locale] = "loc-\(code)" }
        }
        return ScreenshotsContext(primaryLocale: .englishUS, version: version, localizations: localizations)
    }

    static func input(
        document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard,
        live: LiveScreenshots = ScreenshotsDebugDocuments.live,
        context: ScreenshotsContext = context(),
        state: ScreenshotPushState = ScreenshotPushState()
    ) -> ScreenshotPlanInput {
        ScreenshotPlanInput(
            appID: app.id, appName: app.name, document: document, live: live, context: context, fonts: ScreenshotsTestFixtures.fonts, state: state
        )
    }

    // MARK: - Hand-made plans

    /// A live set of `count` screenshots, `live-<locale>-<position>`.
    static func liveSet(_ locale: StoreLocale, display: ScreenshotDisplayType = .iPhone, count: Int) -> LiveScreenshotSet {
        let shots = (0..<count).map { LiveScreenshot(id: "live-\(locale.code)-\($0)", fileName: "old-\($0).png", checksum: "old\($0)") }
        return LiveScreenshotSet(id: "set-\(locale.code)", locale: locale.code, displayType: display, screenshots: shots)
    }

    /// New renders for `slots`, replacing what `live` has there.
    static func group(
        _ locale: StoreLocale,
        display: ScreenshotDisplayType = .iPhone,
        live: LiveScreenshotSet?,
        slots: [Int],
        localizationID: String? = nil
    ) -> ScreenshotPlanGroup {
        let items = slots.map { slot in
            let cell = ScreenshotCellKey(locale: locale.code, displayType: display, slot: slot)
            return ScreenshotPlanItem(
                appID: app.id, cell: cell, slotName: slotNames[slot % slotNames.count], content: .render(job(cell, locale: locale)),
                old: live?.screenshot(slot: slot), source: .you
            )
        }
        return ScreenshotPlanGroup(
            appID: app.id, locale: locale, displayType: display, localizationID: localizationID ?? "loc-\(locale.code)", liveSet: live, items: items
        )
    }

    static func plan(_ groups: [ScreenshotPlanGroup], version: ScreenshotsVersion = ScreenshotsTestFixtures.editableVersion) -> ScreenshotPushPlan {
        var plan = ScreenshotPushPlan.empty(appID: app.id, appName: app.name, version: version, primaryLocaleName: "English (U.S.)")
        plan.groups = groups
        return plan
    }

    static func job(_ cell: ScreenshotCellKey, locale: StoreLocale) -> RenderJob {
        let caption = ScreenshotCaption(headline: "Slot \(cell.slot + 1)")
        let layout = ScreenshotLayoutEngine(catalog: ScreenshotsTestFixtures.fonts).layout(
            ScreenshotsSampleData.template, slot: cell.slot, locale: locale, displayType: cell.displayType, caption: caption
        )
        let key = RenderKey(templateHash: "test", locale: cell.locale, displayType: cell.displayType, slot: cell.slot, caption: caption, captureID: nil)
        return RenderJob(key: key, layout: layout, capture: nil)
    }

    // MARK: - Running

    static func environment(
        _ transport: FakeScreenshotUploadTransport,
        backups: InMemoryScreenshotBackupStore = InMemoryScreenshotBackupStore(),
        clock: ScreenshotPushTestClock = ScreenshotPushTestClock(),
        rate: RequestRateTracker? = nil,
        concurrentSets: Int = 1,
        imageData: (@MainActor (ScreenshotPlanItem) async throws -> Data)? = nil,
        liveData: (@MainActor (LiveScreenshot) async throws -> Data)? = nil
    ) -> ScreenshotPushEnvironment {
        ScreenshotPushEnvironment(
            transport: transport,
            backups: backups,
            imageData: imageData ?? { _ in png },
            liveData: liveData ?? { Data("file of \($0.id)".utf8) },
            rate: rate ?? RequestRateTracker(now: { clock.now }),
            now: { clock.now },
            sleep: { clock.advance(by: $0) },
            concurrentSets: concurrentSets
        )
    }

    /// Runs `plans` to the end of the first round.
    static func push(
        _ plans: [ScreenshotPushPlan],
        selection: Set<ScreenshotPlanItem.ID>? = nil,
        environment: ScreenshotPushEnvironment
    ) async -> ScreenshotPushRun {
        let run = ScreenshotPushRun(plans: plans, selection: selection, environment: environment)
        run.start()
        await run.waitUntilFinished()
        return run
    }
}
#endif
