//
//  AutopilotRunAssistantTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Whether the assistant still has work on a run, when it last sent
/// something, and a problem reported on a screen already captured.
@MainActor
@Suite("Autopilot run · the assistant's work")
struct AutopilotRunAssistantTests {
    private let center = AutopilotTestFixtures.center()
    private let appID = AutopilotTestFixtures.appID

    private func target(_ screen: String, _ display: ScreenshotDisplayType = .iPhone, _ locale: String = "en-US") -> AutopilotCaptureTarget {
        AutopilotTestFixtures.target(screen, display, locale)
    }

    @Test func theAssistantHasWorkWhileSomethingIsLeftForIt() {
        var run = AutopilotTestFixtures.run(.capture)
        #expect(run.assistantHasWork)
        #expect(run.capturesLeft == 8)

        AutopilotTestFixtures.captureAll(&run, except: [target("week")])
        run.problems = [AutopilotTestFixtures.problem(target("week"))]
        #expect(!run.assistantHasWork, "Only the person can answer now")
        #expect(run.capturesLeft == 0)

        run.problems[0].resolution = .retryWithFix
        #expect(run.assistantHasWork)
        #expect(run.capturesLeft == 1)

        #expect(AutopilotTestFixtures.run(.waiting).assistantHasWork, "The plan waits to be picked up")
        #expect(!AutopilotTestFixtures.run(.pick).assistantHasWork)
        #expect(!AutopilotTestFixtures.run(.ready).assistantHasWork)
        #expect(!AutopilotTestFixtures.run(.design).assistantHasWork, "The starters design themselves")
        #expect(AutopilotTestFixtures.run(.design, design: .claudeDesign).assistantHasWork)
        var localizing = AutopilotTestFixtures.run(.localize)
        #expect(!localizing.assistantHasWork)
        localizing.overflows = [AutopilotOverflow(locale: "de-DE", slot: 0, displayType: .iPhone, headline: "", maxLines: 2, fill: 0)]
        #expect(localizing.assistantHasWork)
    }

    @Test func newsIsACaptureAProblemOrADirection() {
        var run = AutopilotTestFixtures.run(.capture)
        let now = AutopilotTestFixtures.now
        #expect(run.lastNewsAt == nil)
        #expect(!run.hasNews(since: now))

        run.captures = [AutopilotTestFixtures.capture(target("today"), second: 30)]
        #expect(run.lastNewsAt == now.addingTimeInterval(30))
        #expect(run.hasNews(since: now))
        #expect(!run.hasNews(since: now.addingTimeInterval(31)))

        var problem = AutopilotTestFixtures.problem(target("week"))
        problem.reportedAt = now.addingTimeInterval(90)
        run.problems = [problem]
        #expect(run.hasNews(since: now.addingTimeInterval(60)))
    }

    /// A screen captured, then reported out of date and retried, is
    /// captured again, and the new capture takes the old one's place.
    @Test func aProblemOnACapturedScreenIsCapturedAgain() async throws {
        center.install(AutopilotTestFixtures.run(.capture))
        let context = AutopilotTestFixtures.context(AutopilotTestFixtures.services(center))
        center.update(appID) { run in AutopilotTestFixtures.captureAll(&run) }
        let old = try #require(center.run(for: appID)?.captures.first { $0.target == target("today", .iPad) })

        center.now = { AutopilotTestFixtures.now.addingTimeInterval(600) }
        let problem = try center.reportProblem(
            appID: appID, target: target("today", .iPad), what: "The phrase is the old small one; recapture it from main.", proposedFix: nil
        )
        await center.resolveProblem(appID: appID, problemID: problem.id, with: .retryWithFix, context: context)
        let waiting = try #require(center.run(for: appID))
        #expect(waiting.stage == .capture, "It doesn't move on with a capture to take again")
        #expect(waiting.retries.map(\.id) == [problem.id])
        #expect(waiting.assistantHasWork)

        center.now = { AutopilotTestFixtures.now.addingTimeInterval(900) }
        let report = AutopilotCaptureReport(target: target("today", .iPad), attempt: 1, score: 0.9, notes: "The bigger phrase")
        _ = try await center.receiveCapture(appID: appID, file: AutopilotTestFixtures.file(.iPad, id: "png-new"), report: report, context: context)
        let run = try #require(center.run(for: appID))
        let captures = run.captures(for: target("today", .iPad))
        #expect(captures.map(\.captureID) == ["png-new"])
        #expect(!captures.contains { $0.id == old.id })
        #expect(run.retries.isEmpty)
    }

    /// A device this Mac can't run takes the place of its screens' problems.
    @Test func aDeviceWideProblemTakesThePlaceOfTheDevicesOthers() throws {
        center.install(AutopilotTestFixtures.run(.capture))
        _ = try center.reportProblem(appID: appID, target: target("week", .iPad, "de-DE"), what: "Blank", proposedFix: nil)
        _ = try center.reportProblem(appID: appID, target: target("today", .iPhone), what: "Blank", proposedFix: nil)
        _ = try center.reportProblem(
            appID: appID, target: target("today", .iPad), what: "This Mac can’t run the iPad simulator.", proposedFix: nil, affectsDevice: true
        )
        let run = try #require(center.run(for: appID))
        #expect(run.openProblems.map(\.target) == [target("today", .iPhone), target("today", .iPad)])
        #expect(run.problemGroups.count == 2)
    }
}
#endif
