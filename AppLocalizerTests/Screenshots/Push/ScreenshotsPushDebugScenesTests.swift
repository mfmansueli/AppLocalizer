//
//  ScreenshotsPushDebugScenesTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The screenshot push scenes open a view each and their simulated App
/// Store Connect reaches the design's states: 40 images in 8 sets, 38 of
/// 40 pushed with the design's two failures, and the Oct 12 push's kept
/// sets.
@MainActor
@Suite("ScreenshotsPushDebugScenes")
struct ScreenshotsPushDebugScenesTests {
    @Test(arguments: ScreenshotsPushDebugScenes.ids)
    func everySceneHasAView(id: String) {
        #expect(ScreenshotsPushDebugScenes.view(for: id) != nil)
    }

    @Test func idsAreUniqueAndLeaveOthersAlone() {
        #expect(Set(ScreenshotsPushDebugScenes.ids).count == ScreenshotsPushDebugScenes.ids.count)
        #expect(ScreenshotsPushDebugScenes.view(for: "sets") == nil)
        #expect(Set(ScreenshotsPushDebugScenes.ids).isDisjoint(with: ScreenshotsDebugScenes.ids))
    }

    private func controller(script: DebugScreenshotUploadScript = DebugScreenshotUploadScript(), autoPush: Bool = false) -> ScreenshotPushController {
        let base = DebugScreenshotsServices()
        let push = DebugScreenshotPushServices(script: script, images: DebugScreenshotImages(fonts: base.fonts), autoPush: autoPush)
        let storePage = DebugStorePageServices(screenshots: DebugPushingScreenshotsServices(base: base, push: push))
        var services = WorkspaceServices.debug
        services.storePage = storePage
        let controller = ScreenshotPushController(history: PushHistory(), rate: RequestRateTracker())
        controller.attach(ScreenshotPushWorkspace(teamName: "Northpier Studio", services: services, apps: { DebugFixtures.apps }))
        return controller
    }

    @Test func reviewShowsFortyImagesInEightSets() async throws {
        let controller = controller()
        await controller.loadPlans(selectedAppID: DebugFixtures.AppID.lumen, allApps: false)
        let plan = try #require(controller.plans[DebugFixtures.AppID.lumen])
        #expect(plan.items.count == 40)
        #expect(plan.groups.map(\.locale.name).prefix(4) == ["Arabic", "Chinese (Simplified)", "Dutch", "Spanish (Mexico)"])
        #expect(plan.missingLocalizations.isEmpty)
        #expect(controller.run == nil)
    }

    @Test func thePartialPushEndsWithTheDesignsTwoFailures() async throws {
        var script = DebugScreenshotUploadScript()
        script.delay = .zero
        script.timeouts = ["zh-Hans_iPhone_1_"]
        script.processingFailures = ["es-MX_iPhone_2_"]
        let controller = controller(script: script, autoPush: true)
        await controller.loadPlans(selectedAppID: DebugFixtures.AppID.lumen, allApps: false)
        let run = try #require(controller.run)
        await run.waitUntilFinished()

        #expect(run.title == "38 of 40 images pushed")
        #expect(run.subtitle == "2 failed. Their live screenshots weren’t touched.")
        let failures = run.items.compactMap(\.status.failureText)
        #expect(failures == [
            "Upload timed out on part 2 of 3. Nothing was replaced; the live screenshot stays.",
            "Apple couldn’t process the image (IMAGE_TOOL_FAILURE). The live screenshot stays.",
        ])

        run.retryFailed()
        await run.waitUntilFinished()
        #expect(run.title == "All 40 images pushed")
    }

    @Test func theOctober12PushKeptThreeLocalesSets() throws {
        let base = DebugScreenshotsServices()
        let push = DebugScreenshotPushServices(images: DebugScreenshotImages(fonts: base.fonts))
        let record = ScreenshotsPushDebugData.screenshotRecord
        let backupID = try #require(record.screenshots?.backupID)
        let backup = try #require(push.backups.backup(id: backupID, appID: record.appID))
        #expect(backup.locales == ["en-US", "de-DE", "ja"])
        #expect(backup.images(locale: "de-DE").count == 10)
        #expect(record.title == "Screenshots · 80 images in 8 locales")
        #expect(record.screenshots?.keptTitle == "Kept on this Mac: the 3 sets this push replaced")
        #expect(ScreenshotsPushDebugData.records.map(\.title) == ["Screenshots · 80 images in 8 locales", "Store Page · 24 texts in 8 locales"])
    }

    @Test func theRestoreSceneOpensOnGermanOnce() {
        let base = DebugScreenshotsServices()
        let restore = ScreenshotRestorePresentation(recordID: ScreenshotsPushDebugData.recordID, locale: "de-DE")
        let push = DebugScreenshotPushServices(images: DebugScreenshotImages(fonts: base.fonts), restoreOnOpen: restore)
        #expect(push.consumeRestoreOnOpen() == restore)
        #expect(push.consumeRestoreOnOpen() == nil)
    }
}
#endif
