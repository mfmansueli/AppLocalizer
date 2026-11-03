//
//  AutopilotDuoRowTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The plan's iPhone Duo row: the inner display (the default), the cover
/// display, or both, side by side in each image or as separate
/// screenshots (inner then cover, capped at Apple's 10); what each
/// captures, in which order, and how each capture's size is checked.
@MainActor
@Suite("iPhone Duo row")
struct AutopilotDuoRowTests {
    private let appID = AutopilotTestFixtures.appID

    /// `count` screens on iPhone and iPhone Duo, in English, the Duo row
    /// set to `screens` and `both`.
    static func plan(
        screens count: Int = 6, _ screens: AutopilotDuoScreens? = nil, _ both: AutopilotDuoBoth? = nil
    ) -> AutopilotPlan {
        var plan = AutopilotTestFixtures.smallPlan
        plan.screens = (1...count).map { AutopilotScreen(name: "Screen \($0)", steps: "launch → \($0)", caption: "Caption \($0)") }
        plan.displayTypes = [.iPhone, .iPhoneDuo]
        plan.localeCodes = ["en-US"]
        plan.runChoice.duoScreens = screens
        plan.runChoice.duoBoth = both
        return plan
    }

    private func duo(_ plan: AutopilotPlan, slot: Int, _ pose: AutopilotDuoPose? = nil) -> AutopilotCaptureTarget {
        var target = AutopilotTestFixtures.target(plan.screens[slot].id, .iPhoneDuo)
        target.duoPose = pose ?? plan.duoPoses(forSlot: slot).first
        return target
    }

    // MARK: - What each choice captures

    @Test func theInnerDisplayIsTheDefault() {
        let plan = Self.plan()
        #expect(plan.duoScreens == .inner)
        #expect(plan.duoSlots(.open) == Array(0..<6))
        #expect(plan.duoSlots(.closed).isEmpty)
        #expect(plan.duoShots.count == 6)
        #expect(plan.duoPose(for: duo(plan, slot: 0)) == .open)
        #expect(plan.duoPose(for: AutopilotTestFixtures.target(plan.screens[0].id)) == nil, "iPhone has no pose")
        #expect(ScreenshotStudioModel.duoNote(plan)
            == "Unfolded, as Apple requires: the inner display at 2007 × 2853. AppLocalizer opens the Duo in Device Hub for each capture.")
        #expect(AutopilotPlanTable.duoTitle(plan) == "iPhone Duo · inner display, opened in Device Hub · the same screens as iPhone")
    }

    @Test func theCoverDisplayIsFoldedOnly() {
        let plan = Self.plan(.cover)
        #expect(plan.duoSlots(.closed) == Array(0..<6))
        #expect(plan.duoSlots(.open).isEmpty)
        #expect(plan.targets.filter { $0.displayType == .iPhoneDuo }.allSatisfy { $0.duoPose == .closed })
        #expect(ScreenshotStudioModel.duoNote(plan) == """
        Folded: the app on the cover display, placed on the 2007 × 2853 canvas. Faster, since the Duo never opens, but people don’t see the big screen.
        """)
        #expect(AutopilotPlanTable.duoTitle(plan) == "iPhone Duo · cover display, folded · the same screens as iPhone")
    }

    @Test func bothSideBySideCapturesEachScreenTwiceForOneImage() {
        let plan = Self.plan(.both, .sideBySide)
        #expect(plan.duoShots.count == 6)
        let allPairs = plan.duoShots.allSatisfy(\.isPair)
        #expect(allPairs)
        #expect(plan.targets.count(where: { $0.displayType == .iPhoneDuo }) == 12)
        #expect(plan.screensPerLanguage == 12, "6 on iPhone, 6 on iPhone Duo")
        #expect(plan.duoCoverSlots.isEmpty, "Laid out as the unfolded Duo's")
        #expect(ScreenshotStudioModel.duoNote(plan)
            == "Each screenshot shows the Duo unfolded with the folded cover beside it: 6 per language, both states in one image.")
        #expect(AutopilotPlanTable.duoTitle(plan) == "iPhone Duo · inner and cover display, side by side · the same screens as iPhone")
    }

    @Test(arguments: [(3, 6, 3), (5, 10, 5), (6, 10, 4), (8, 10, 2)])
    func bothSeparateIsInnerThenCoverUnderApplesTen(screens: Int, shots: Int, covers: Int) {
        let plan = Self.plan(screens: screens, .both, .separate)
        #expect(plan.duoShots.count == shots)
        #expect(plan.duoSeparateCovers == covers)
        #expect(plan.duoShots.prefix(2).map(\.poses) == [[.open], [.closed]], "Inner, then cover")
        #expect(plan.duoSlots(.closed) == Array(0..<covers))
        #expect(plan.duoDeviceScreens.prefix(2).map(\.name) == ["Screen 1 · inner", "Screen 1 · cover"])
        #expect(plan.duoDeviceScreens.allSatisfy { $0.captionSlot != nil })
    }

    @Test func theSeparateNoteSaysWhenOnlySomeScreensGetACoverOne() {
        #expect(ScreenshotStudioModel.duoNote(Self.plan(screens: 5, .both, .separate))
            == "Each screen unfolded, then folded: 10 screenshots per language.")
        #expect(ScreenshotStudioModel.duoNote(Self.plan(screens: 6, .both, .separate))
            == "Each screen unfolded, then folded: 10 screenshots per language. Apple allows 10, so only the first 4 screens get a folded one.")
        #expect(AutopilotPlanTable.duoTitle(Self.plan(.both, .separate))
            == "iPhone Duo · inner and cover display, as separate screenshots · the same screens as iPhone")
    }

    @Test func eachChoicePlacesItsCapturesOnTheRightSlot() {
        let inner = Self.plan()
        #expect(inner.duoPlacement(slot: 2, pose: .open)?.slot == 2)
        #expect(inner.duoPlacement(slot: 2, pose: .closed) == nil)
        #expect(Self.plan(.cover).duoPlacement(slot: 2, pose: .closed)?.isCompanion == false)
        let pair = Self.plan(.both, .sideBySide)
        #expect(pair.duoPlacement(slot: 2, pose: .open).map { [$0.slot] + [$0.isCompanion ? 1 : 0] } == [2, 0])
        #expect(pair.duoPlacement(slot: 2, pose: .closed).map { [$0.slot] + [$0.isCompanion ? 1 : 0] } == [2, 1])
        let separate = Self.plan(.both, .separate)
        #expect(separate.duoPlacement(slot: 1, pose: .open)?.slot == 2)
        #expect(separate.duoPlacement(slot: 1, pose: .closed)?.slot == 3)
        #expect(separate.duoPlacement(slot: 5, pose: .closed) == nil, "Past Apple's 10")
    }

    // MARK: - Order

    @Test func theClosedScreensComeFirstThenTheOpenOnes() {
        let plan = Self.plan(.both, .sideBySide)
        var run = AutopilotTestFixtures.run(.capture, plan: plan)
        let closed = (0..<6).map { duo(plan, slot: $0, .closed) }
        let open = (0..<6).map { duo(plan, slot: $0, .open) }
        #expect(run.duoPoseWanted == .closed)
        #expect(run.nextTargets.filter { $0.displayType == .iPhoneDuo } == closed)
        #expect(run.nextTargets.count(where: { $0.displayType == .iPhone }) == 6, "iPhone doesn't wait")

        for target in closed {
            run.captures.append(AutopilotTestFixtures.capture(target, in: plan))
        }
        #expect(run.duoPoseWanted == .open)
        #expect(run.nextTargets.filter { $0.displayType == .iPhoneDuo } == open)

        AutopilotTestFixtures.captureAll(&run)
        #expect(run.duoPoseWanted == nil)
    }

    @Test func theInnerDisplayAloneNeverWaitsForAFold() {
        let run = AutopilotTestFixtures.run(.capture, plan: Self.plan())
        #expect(run.duoPoseWanted == .open)
        #expect(run.nextTargets.count(where: { $0.displayType == .iPhoneDuo }) == 6)
    }

    /// A problem with the Duo itself (closed, stuck) holds every screen on
    /// it, so the assistant gets none, but the watcher still knows what to
    /// fix: open it once only open screens are left.
    @Test func aDeviceProblemStillSaysWhichPoseIsWanted() {
        let plan = Self.plan(screens: 3, .both, .sideBySide)
        var run = AutopilotTestFixtures.run(.capture, plan: plan)
        var stuck = AutopilotTestFixtures.problem(duo(plan, slot: 0, .closed))
        stuck.affectsDevice = true
        run.problems.append(stuck)
        #expect(run.nextTargets.allSatisfy { $0.displayType != .iPhoneDuo })
        #expect(run.duoPoseWanted == .closed)

        for slot in 0..<3 {
            run.captures.append(AutopilotTestFixtures.capture(duo(plan, slot: slot, .closed), in: plan))
        }
        #expect(run.duoPoseWanted == .open)
    }

    /// A plan that switches from the cover display to the inner one stops
    /// counting the folded captures.
    @Test func switchingTheRowCapturesTheOtherDisplay() {
        var plan = Self.plan(screens: 3, .cover)
        var run = AutopilotTestFixtures.run(.capture, plan: plan)
        AutopilotTestFixtures.captureAll(&run)
        #expect(plan.targets.filter { $0.displayType == .iPhoneDuo }.allSatisfy(run.isSettled))

        plan.runChoice.duoScreens = .inner
        run.plan = plan
        let open = plan.targets.filter { $0.displayType == .iPhoneDuo }
        #expect(open.allSatisfy { $0.duoPose == .open })
        #expect(open.allSatisfy { !run.isSettled($0) })
    }

    // MARK: - Sizes

    @Test func aClosedScreenTakesOnlyTheCoverDisplay() throws {
        try AutopilotCenter.checkSize(PixelSize(width: 1398, height: 2034), for: .iPhoneDuo, duoPose: .closed)
        try AutopilotCenter.checkSize(PixelSize(width: 2034, height: 1398), for: .iPhoneDuo, duoPose: .closed)
        #expect(throws: AutopilotError.self) {
            try AutopilotCenter.checkSize(PixelSize(width: 2853, height: 2007), for: .iPhoneDuo, duoPose: .closed)
        }
    }

    @Test func anOpenScreenTakesOnlyTheInnerDisplay() throws {
        try AutopilotCenter.checkSize(PixelSize(width: 2853, height: 2007), for: .iPhoneDuo, duoPose: .open)
        try AutopilotCenter.checkSize(PixelSize(width: 2007, height: 2853), for: .iPhoneDuo, duoPose: .open)
        #expect(throws: AutopilotError.self) {
            try AutopilotCenter.checkSize(PixelSize(width: 1398, height: 2034), for: .iPhoneDuo, duoPose: .open)
        }
    }

    /// Both side by side: one target per screen and size, so a cover
    /// capture for a screen goes to its closed target, logged with the
    /// fold.
    @Test func theCenterSortsACaptureByTheDisplayItShows() async throws {
        let center = AutopilotTestFixtures.center()
        let context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
        let plan = Self.plan(screens: 3, .both, .sideBySide)
        center.install(AutopilotTestFixtures.run(.capture, plan: plan))
        let report = AutopilotCaptureReport(target: AutopilotTestFixtures.target(plan.screens[0].id, .iPhoneDuo), attempt: 1, score: 0.9, notes: "")
        let cover = try await center.receiveCapture(
            appID: appID, file: CaptureFile(id: "png-cover", pixelSize: CaptureSizeRules.duoOuterSize), report: report, context: context
        )
        #expect(cover.target.duoPose == .closed)
        let log = try #require(center.run(for: appID)?.log.map(\.text))
        #expect(log.contains { $0.hasPrefix("iPhone Duo folded · launch on the cover display -AppleLanguages (en-US)") })
    }

    /// The closed captures frame the folded phone, so only the open ones
    /// turn iPhone Duo's canvas.
    @Test func onlyTheOpenCapturesTurnTheDuosCanvas() {
        let plan = Self.plan(.both, .sideBySide)
        var run = AutopilotTestFixtures.run(.localize, plan: plan)
        for slot in 0..<6 {
            var open = AutopilotTestFixtures.capture(duo(plan, slot: slot, .open), in: plan)
            open.pixelSize = CaptureSizeRules.duoInnerSize.rotated
            run.captures.append(open)
            run.captures.append(AutopilotTestFixtures.capture(duo(plan, slot: slot, .closed), in: plan))
        }
        let canvas = TemplateCanvas(iphone: .portrait, ipad: .landscape)
        #expect(AutopilotLocalizer.canvas(canvas, matching: run).duo == .landscape)
    }
}
#endif
