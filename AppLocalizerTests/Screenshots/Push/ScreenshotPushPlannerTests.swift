//
//  ScreenshotPushPlannerTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What a screenshot push would send for Lumen Journal's sample: the
/// design's 40 images in 8 sets, renders failing checks left out, discards
/// kept until their render changes, and queued restores.
@MainActor
@Suite("ScreenshotPushPlanner")
struct ScreenshotPushPlannerTests {
    private typealias Fixtures = ScreenshotPushTestFixtures

    private func plan(
        document: ScreenshotsDocument = ScreenshotsDebugDocuments.standard,
        context: ScreenshotsContext = Fixtures.context(),
        state: ScreenshotPushState = ScreenshotPushState()
    ) -> ScreenshotPushPlan {
        ScreenshotPushPlanner().plan(Fixtures.input(document: document, context: context, state: state))
    }

    @Test func theSampleSendsFortyImagesInEightSets() {
        let plan = plan()
        #expect(plan.items.count == 40)
        #expect(plan.groups.count == 8)
        #expect(plan.groups.allSatisfy { $0.items.count == 5 && $0.liveSet == nil })
        #expect(plan.heading == "Lumen Journal · Screenshots · Version 1.4")
    }

    @Test func setsAreOrderedIPhoneFirstThenByLocaleName() {
        let names = plan().groups.map { "\($0.locale.name) \($0.displayType.shortTitle)" }
        #expect(names == [
            "Arabic iPhone", "Chinese (Simplified) iPhone", "Dutch iPhone", "Spanish (Mexico) iPhone",
            "Arabic iPad", "Chinese (Simplified) iPad", "Dutch iPad", "Spanish (Mexico) iPad",
        ])
    }

    @Test func rendersAlreadyLiveAreLeftOut() {
        let cells = Set(plan().items.map(\.cell.locale))
        #expect(cells.isDisjoint(with: ScreenshotsSampleData.liveLocales))
    }

    @Test func rendersFailingAChecksAreExcludedWithTheirReason() {
        let failed = plan().failedChecks
        #expect(!failed.isEmpty)
        #expect(failed.allSatisfy { $0.failedCheck != nil })
        #expect(plan().items.allSatisfy { item in !failed.contains { $0.cell == item.cell } })
    }

    @Test func localesNotOnTheVersionWaitForALocalization() {
        let plan = plan(context: Fixtures.context(missing: ["nl-NL"]))
        #expect(plan.items.count == 30)
        #expect(plan.missingLocalizations.count == 10)
        #expect(plan.missingLocalizations.allSatisfy { $0.cell.locale == "nl-NL" && !$0.isFailedCheck })
    }

    @Test func aLiveVersionBlocksThePush() {
        let plan = plan(context: Fixtures.context(version: ScreenshotsTestFixtures.liveVersion))
        #expect(!plan.canPush)
        #expect(plan.blockedReason?.contains("1.3") == true)
    }

    @Test func aDiscardKeepsTheRenderOutUntilItChanges() throws {
        let first = try #require(plan().items.first)
        let key = try #require(first.renderKey)
        var state = ScreenshotPushState()
        state.kept[first.cell] = key
        let discarded = plan(state: state)
        #expect(discarded.items.count == 39)
        #expect(discarded.kept.map(\.id) == [first.id])

        state.kept[first.cell] = RenderKey(rawValue: key.rawValue + "-before")
        #expect(plan(state: state).items.count == 40)
    }

    @Test func aQueuedRestoreReplacesAPinnedLocalesSet() throws {
        var document = ScreenshotsDebugDocuments.standard
        document.scope.pin("de-DE", at: .now)
        let images = (0..<5).map { slot in
            ScreenshotBackupImage(
                backupID: "b1", locale: "de-DE", displayType: .iPhone, position: slot, liveID: "old-\(slot)",
                fileName: "Bild-\(slot + 1).png", checksum: "kept\(slot)", pixelSize: nil, origin: .uploadedByHand
            )
        }
        var state = ScreenshotPushState()
        state.queue(ScreenshotRestoreRequest(locale: "de-DE", backupID: "b1", backupDate: ScreenshotsSampleData.liveDate, images: images))
        let plan = plan(document: document, state: state)
        let restore = try #require(plan.groups.first { $0.isRestore })
        #expect(restore.locale.code == "de-DE")
        #expect(restore.items.map(\.fileName) == ["Bild-1.png", "Bild-2.png", "Bild-3.png", "Bild-4.png", "Bild-5.png"])
        #expect(restore.items.allSatisfy { $0.old != nil && $0.source == .restore })
        #expect(restore.deleteCount == 5)
    }

    @Test func aRestoreSkipsSlotsAlreadyShowingTheKeptFile() {
        var document = ScreenshotsDebugDocuments.standard
        document.scope.pin("de-DE", at: .now)
        let image = ScreenshotBackupImage(
            backupID: "b1", locale: "de-DE", displayType: .iPhone, position: 0, liveID: "old-0", fileName: "Bild-1.png",
            checksum: "sample-de-DE-APP_IPHONE_67-0", pixelSize: nil, origin: .template
        )
        var state = ScreenshotPushState()
        state.queue(ScreenshotRestoreRequest(locale: "de-DE", backupID: "b1", backupDate: .now, images: [image]))
        #expect(plan(document: document, state: state).groups.allSatisfy { !$0.isRestore })
    }

    @Test func aRestoreForAnUnpinnedLocaleIsIgnored() {
        let image = ScreenshotBackupImage(
            backupID: "b1", locale: "de-DE", displayType: .iPhone, position: 0, liveID: "old-0", fileName: "", checksum: "kept",
            pixelSize: nil, origin: .uploadedByHand
        )
        var state = ScreenshotPushState()
        state.queue(ScreenshotRestoreRequest(locale: "de-DE", backupID: "b1", backupDate: .now, images: [image]))
        #expect(plan(state: state).groups.allSatisfy { !$0.isRestore })
    }

    @Test func fileNamesSayLocaleDisplayAndSlot() throws {
        let item = try #require(plan().items.first)
        #expect(item.fileName == "ar-SA_iPhone_1_Today.png")
        #expect(item.title(localeName: "Arabic") == "Arabic · iPhone · 1 Today")
    }
}
#endif
