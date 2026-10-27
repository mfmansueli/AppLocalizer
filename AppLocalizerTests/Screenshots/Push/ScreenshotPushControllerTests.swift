//
//  ScreenshotPushControllerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Review & Push's screenshot side: plans per app, discards and Undo, the
/// push and its Activity record, and restores queued from Activity.
@MainActor
@Suite("ScreenshotPushController")
struct ScreenshotPushControllerTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    @Test func plansTheSelectedApp() async throws {
        let harness = ScreenshotPushControllerHarness()
        await harness.load()
        let plan = try #require(harness.plan)
        #expect(plan.items.count == 40)
        #expect(harness.controller.primaryLocaleName(for: harness.app.id) == "English (U.S.)")
        #expect(harness.controller.canPush)
    }

    @Test func theVersionIsReadAgainOnlyOnRefresh() async {
        let harness = ScreenshotPushControllerHarness()
        await harness.load()
        await harness.load()
        #expect(harness.push.contextCount == 1)
        await harness.load(refreshCount: 1)
        #expect(harness.push.contextCount == 2)
    }

    @Test func servicesThatCantPushPlanNothing() async {
        let harness = ScreenshotPushControllerHarness()
        harness.controller.attach(harness.workspace(FakeScreenshotsServices(document: ScreenshotsDebugDocuments.standard)))
        await harness.load()
        #expect(!harness.controller.canPush)
        #expect(harness.controller.plans.isEmpty)
    }

    @Test func discardKeepsWhatsLiveUntilUndo() async throws {
        let harness = ScreenshotPushControllerHarness()
        await harness.load()
        let item = try #require(harness.plan?.items.first)
        harness.controller.discard([item])
        #expect(harness.plan?.items.count == 39)
        #expect(harness.plan?.kept.map(\.id) == [item.id])
        #expect(harness.push.stateStore.state(appID: harness.app.id).kept[item.cell] == item.renderKey)

        await harness.load()
        #expect(harness.plan?.items.count == 39)

        await harness.controller.undoDiscards(appIDs: [harness.app.id])
        #expect(harness.plan?.items.count == 40)
        #expect(harness.plan?.kept.isEmpty == true)
    }

    @Test func aPushIsRecordedAndNotedInTheDocument() async throws {
        let history = PushHistory()
        let harness = ScreenshotPushControllerHarness(context: Fixtures.context(missing: ["ar-SA", "zh-Hans", "es-MX"]), history: history)
        var pushedApps: Set<StoreApp.ID> = []
        harness.controller.onPushed = { pushedApps.formUnion($0) }
        await harness.load()
        let plan = try #require(harness.plan)
        #expect(plan.items.count == 10)
        let chosen = Set(plan.items.prefix(2).map(\.id))
        let pushedBefore = harness.screenshots.storedDocument?.pushed.count ?? 0

        harness.controller.push([plan], selection: chosen)
        await harness.controller.run?.waitUntilFinished()

        #expect(harness.controller.run?.title == "All 2 images pushed")
        let record = try #require(history.records.first)
        #expect(record.title == "Screenshots · 2 images in 1 locale")
        #expect(record.appName == harness.app.name)
        #expect(record.screenshots?.pushedCount == 2)
        #expect(record.screenshots?.backupID == nil)
        #expect(record.succeededCount == 2)
        #expect(harness.screenshots.storedDocument?.pushed.count == pushedBefore + 2)
        #expect(pushedApps == [harness.app.id])
        #expect(harness.controller.revisions[harness.app.id] == 1)

        harness.controller.dismissFinished()
        #expect(harness.controller.run == nil)
    }

    @Test func aRestoreIsQueuedForReviewAndPinsTheLocale() async throws {
        let harness = ScreenshotPushControllerHarness()
        let backup = try harness.keepGermanSet()
        await harness.load()
        let record = PushRecord(
            date: ScreenshotsSampleData.liveDate, appID: harness.app.id, appName: harness.app.name, title: "Screenshots", pushed: [],
            screenshots: ScreenshotPushSummary(
                pushedCount: 80, failures: [], locales: ["de-DE"], keptLocales: ["de-DE"], backupID: backup.id, isRestore: false
            )
        )
        #expect(harness.controller.backup(for: record)?.images.count == 5)

        let queued = await harness.controller.queueRestore(locale: .german, from: backup, appID: harness.app.id)

        #expect(queued)
        #expect(harness.screenshots.storedDocument?.scope.isPinned("de-DE") == true)
        #expect(harness.push.stateStore.state(appID: harness.app.id).restores.map(\.locale) == ["de-DE"])
        let restore = try #require(harness.plan?.groups.first { $0.isRestore })
        #expect(restore.items.map(\.fileName) == ["de-1.png", "de-2.png", "de-3.png", "de-4.png", "de-5.png"])
        #expect(harness.controller.notice?.contains("5 screenshots") == true)
        #expect(harness.controller.revisions[harness.app.id] == 1)
    }

    @Test func pushingARestoreClearsIt() async throws {
        let harness = ScreenshotPushControllerHarness()
        let backup = try harness.keepGermanSet()
        await harness.load()
        await harness.controller.queueRestore(locale: .german, from: backup, appID: harness.app.id)
        let plan = try #require(harness.plan)
        let restoreIDs = Set(plan.groups.filter(\.isRestore).flatMap(\.items).map(\.id))

        harness.controller.push([plan], selection: restoreIDs)
        await harness.controller.run?.waitUntilFinished()

        #expect(harness.controller.run?.doneCount == 5)
        #expect(harness.push.stateStore.state(appID: harness.app.id).restores.isEmpty)
        #expect(harness.history.records.first?.title == "Screenshots restored · 5 images in 1 locale")
        #expect(harness.push.transport.log.filter { $0.hasPrefix("delete") }.count == 5)
    }

    @Test func activityNamesThePrimaryLocaleBeforeReviewOpens() async {
        let harness = ScreenshotPushControllerHarness()
        #expect(harness.controller.primaryLocaleName(for: harness.app.id) == "the primary locale")
        await harness.controller.loadAppsIfNeeded()
        #expect(harness.controller.primaryLocaleName(for: harness.app.id) == "English (U.S.)")
    }

    @Test func showInCaptionsIsHandedToTheScreenshotsView() {
        let harness = ScreenshotPushControllerHarness()
        let cell = ScreenshotCellKey(locale: "de-DE", displayType: .iPhone, slot: 2)
        harness.controller.showInCaptions(ScreenshotPlanExclusion(appID: harness.app.id, cell: cell, localeName: "German", failedCheck: "Overflow"))
        #expect(harness.controller.captionsRequest?.cell == cell)
        harness.controller.consumeCaptionsRequest()
        #expect(harness.controller.captionsRequest == nil)
    }

    @Test func anotherAccountStartsOver() async {
        let harness = ScreenshotPushControllerHarness()
        await harness.load()
        #expect(!harness.controller.plans.isEmpty)
        let other = harness.workspace(FakePushingScreenshotsServices(base: harness.screenshots, push: harness.push))
        harness.controller.attach(ScreenshotPushWorkspace(teamName: "Another Team", services: other.services, apps: other.apps))
        #expect(harness.controller.plans.isEmpty)
    }
}
#endif
