//
//  GuidedInterfaceGapTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Lumen's iPad screens exist in only 4 languages: Plan says the run
/// captures the others, Start notes the gap, and Review checks every
/// device and that every screenshot shows Lumen in its own language.
@MainActor
@Suite("Interface gap")
struct GuidedInterfaceGapTests {
    private static func check(_ id: String, in checks: [GuidedCheck]) -> GuidedCheck? {
        checks.first { $0.id == id }
    }

    private static var iPadGap: AutopilotInterfaceGap {
        AutopilotInterfaceGap(displayType: .iPad, capturedCount: 4, languageCount: 18)
    }

    // MARK: - The gap

    @Test func lumensIPadIsCapturedInOnlySomeLanguages() throws {
        let plan = StudioDebugRuns.plan
        let captures = ScreenshotsSampleData.captures
        let gaps = AutopilotInterfaceGap.gaps(in: plan, captures: captures)
        let iPad = try #require(gaps.first)
        #expect(gaps.count == 1, "iPhone isn't a gap: \(gaps)")
        #expect(iPad.displayType == .iPad)
        #expect(iPad.capturedCount == 4)
        #expect(iPad.languageCount == plan.localeCodes.count)
        #expect(iPad.missingCount == plan.localeCodes.count - 4)
    }

    @Test func aDeviceWithNoCapturesYetIsNewNotAGap() {
        var plan = StudioDebugRuns.plan
        plan.setPlans(.mac, true)
        let gaps = AutopilotInterfaceGap.gaps(in: plan, captures: ScreenshotsSampleData.captures)
        #expect(!gaps.contains { $0.displayType == .mac })
    }

    @Test func capturingInOneLanguageFillsNoGap() {
        var plan = StudioDebugRuns.plan
        plan.capturesEachLanguage = false
        #expect(AutopilotInterfaceGap.gaps(in: plan, captures: ScreenshotsSampleData.captures).isEmpty)
    }

    // MARK: - Plan

    @Test func theCaptureLineSaysItFillsTheGap() throws {
        let rows = GuidedPlanTimeline.rows(
            plan: StudioDebugRuns.plan, client: "Claude Code", design: .claudeDesign, brand: "Northpier Brand",
            gaps: [Self.iPadGap], app: "Lumen"
        )
        let capture = try #require(rows.first { $0.kind == .capture })
        #expect(capture.detail.hasSuffix("""
        It also fills a gap: Lumen’s iPad screens exist in only 4 languages today, so this run captures the other 14 \
        and no screenshot shows the English interface under a translated caption.
        """), "\(capture.detail)")
    }

    @Test func withoutAGapTheCaptureLineIsAsBefore() throws {
        let rows = GuidedPlanTimeline.rows(plan: StudioDebugRuns.plan, client: "Claude Code", design: .claudeDesign, brand: nil, app: "Lumen")
        let capture = try #require(rows.first { $0.kind == .capture })
        #expect(!capture.detail.contains("gap"))
    }

    @Test func aGapOnADeviceTheRunLeftOutIsntMentioned() throws {
        var plan = StudioDebugRuns.plan
        plan.setPlans(.iPad, false)
        let rows = GuidedPlanTimeline.rows(plan: plan, client: "Claude Code", design: .none, brand: nil, gaps: [Self.iPadGap], app: "Lumen")
        let capture = try #require(rows.first { $0.kind == .capture })
        #expect(!capture.detail.contains("gap"))
    }

    @Test func severalDevicesSayEachCount() {
        let gaps = [Self.iPadGap, AutopilotInterfaceGap(displayType: .mac, capturedCount: 2, languageCount: 18)]
        #expect(AutopilotInterfaceGap.before(gaps, app: "Lumen") == "Lumen’s iPad screens exist in only 4 languages and its Mac screens in 2")
        #expect(AutopilotInterfaceGap.existed(gaps) == "before, iPad screens existed in 4 and Mac screens in 2")
        #expect(GuidedPlanTimeline.gapSentence(gaps, plan: StudioDebugRuns.plan, app: "Lumen")?.contains("so this run captures the others") == true)

        let same = [Self.iPadGap, AutopilotInterfaceGap(displayType: .iPhoneDuo, capturedCount: 4, languageCount: 18)]
        #expect(AutopilotInterfaceGap.before(same, app: "Lumen") == "Lumen’s iPad and iPhone Duo screens exist in only 4 languages")
        #expect(AutopilotInterfaceGap.existed(same) == "before, iPad and iPhone Duo screens existed in 4")
    }

    // MARK: - Start

    @Test func startNotesTheGap() {
        let center = AutopilotTestFixtures.center()
        let appID = AutopilotTestFixtures.appID
        center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)
        center.start(appID: appID, interfaceGaps: [Self.iPadGap])
        #expect(center.run(for: appID)?.interfaceGaps == [Self.iPadGap])
    }

    @Test func startWithoutAGapNotesNone() {
        let center = AutopilotTestFixtures.center()
        let appID = AutopilotTestFixtures.appID
        center.prepare(appID: appID, versionString: "1.4", plan: AutopilotTestFixtures.smallPlan)
        center.start(appID: appID)
        #expect(center.run(for: appID)?.interfaceGaps == nil)
    }

    // MARK: - Review

    @Test func reviewChecksEveryDeviceAndTheGapFilled() throws {
        let run = StudioDebugRuns.run(.ready)
        let checks = GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen")
        #expect(checks.prefix(2).map(\.id) == ["devices", "interface"], "First, as on the board")
        let devices = try #require(Self.check("devices", in: checks))
        #expect(devices.text == "Every device in the run: iPhone and iPad, each checked in every language")
        #expect(devices.state == .passed)
        let interface = try #require(Self.check("interface", in: checks))
        let total = run.plan.localeCodes.count
        #expect(interface.text == "Every screenshot shows Lumen in its own language: iPad captured in all \(total) (before, iPad screens existed in 4)")
        #expect(interface.state == .passed)
    }

    /// Board 21's "6 · Review every device": iPad and Mac had 4 languages.
    @Test func reviewingEveryDeviceNamesEachGapFilled() throws {
        let run = try #require(StudioDebugGuided.scene(for: "ap-review-devices")?.run)
        let checks = GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen")
        #expect(Self.check("devices", in: checks)?.text
            == "Every device in the run: iPhone, iPad, iPhone Duo, Mac, Vision Pro, and Apple Watch, each checked in every language")
        let total = run.plan.localeCodes.count
        #expect(Self.check("interface", in: checks)?.text
            == "Every screenshot shows Lumen in its own language: iPad and Mac captured in all \(total) (before, iPad and Mac screens existed in 4)")
        #expect(Self.check("interface", in: checks)?.state == .passed)
    }

    @Test func withoutAGapEveryScreenshotIsInItsOwnLanguage() {
        var run = StudioDebugRuns.run(.ready)
        run.interfaceGaps = nil
        let interface = Self.check("interface", in: GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen"))
        #expect(interface?.text == "Every screenshot shows Lumen in its own language")
    }

    @Test func aLanguageWithoutItsCaptureNeedsALook() throws {
        var run = StudioDebugRuns.run(.ready)
        let missing = try #require(run.plan.targets.first { $0.displayType == .iPad && $0.locale == "ko" })
        run.captures.removeAll { $0.target == missing }
        let interface = try #require(Self.check("interface", in: GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen")))
        #expect(interface.state == .attention)
        #expect(interface.text == "Not captured: iPad in 1 language; those screenshots show the English interface")
    }

    @Test func capturedInOneLanguageIsThePersonsChoice() {
        var run = StudioDebugRuns.run(.ready)
        run.plan.capturesEachLanguage = false
        let interface = Self.check("interface", in: GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen"))
        #expect(interface?.state == .passed, "Not an error: the person chose it")
        #expect(interface?.text == "Captured in English only, as planned: every language shows Lumen’s English interface")
    }

    @Test func languagesNotCheckedYetLeaveTheDevicesToLookAt() {
        let run = StudioDebugRuns.run(.localize)
        let devices = Self.check("devices", in: GuidedReviewChecks.checks(for: .screenshots, run: run, app: "Lumen"))
        #expect(devices?.state == .attention)
        #expect(devices?.text == "Every device in the run: iPhone and iPad")
    }
}
#endif
