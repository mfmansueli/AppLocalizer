//
//  AutopilotRunTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What a run works out from its captures, problems, picks and
/// directions.
@MainActor
@Suite("Autopilot run")
struct AutopilotRunTests {
    private let today = AutopilotTestFixtures.target("today")
    private let germanToday = AutopilotTestFixtures.target("today", .iPhone, "de-DE")

    @Test func thePlanTargetsEveryDeviceLanguageAndScreen() {
        var plan = AutopilotTestFixtures.smallPlan
        #expect(plan.targets.count == 8)
        #expect(plan.targets.first == today)
        #expect(plan.targets.last == AutopilotTestFixtures.target("week", .iPad, "de-DE"))
        #expect(plan.scopeTitle == "\(["iPhone", "iPad"].formatted(.list(type: .and))) · 2 languages · 2 screens")
        #expect(plan.slot(of: "week") == 1)

        plan.capturesEachLanguage = false
        #expect(plan.capturedLocales == ["en-US"])
        #expect(plan.targets.count == 4)
        #expect(AutopilotScreen(name: "Photo entry").id == "photo-entry")
        #expect(AutopilotScreen(name: "Écrire · Jour").id == "ecrire-jour")
    }

    @Test func capturesCountTowardsWhatsLeft() {
        var run = AutopilotTestFixtures.run(.capture)
        #expect(run.totalCaptures == 8)
        #expect(run.remainingTargets == run.plan.targets)
        #expect(!run.isCaptureComplete)

        run.captures = [
            AutopilotTestFixtures.capture(today, second: 1), AutopilotTestFixtures.capture(today, attempt: 2, second: 5),
            AutopilotTestFixtures.capture(germanToday, second: 3),
        ]
        #expect(run.capturedCount == 2)
        #expect(run.remainingTargets.count == 6)
        #expect(!run.remainingTargets.contains(today))
        #expect(run.latestCapture?.id == "cap-today-iphone-en-US-2")
    }

    @Test func anOpenProblemHoldsTheRunUntilThePersonAnswers() {
        let blocked = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var run = AutopilotTestFixtures.run(.capture)
        AutopilotTestFixtures.captureAll(&run, except: [blocked])
        run.problems = [AutopilotTestFixtures.problem(blocked)]
        #expect(run.remainingTargets.isEmpty, "The blocked screen isn't asked for again")
        #expect(run.openProblems.count == 1)
        #expect(!run.isCaptureComplete)

        run.problems[0].resolution = .uploadedByHand
        #expect(run.isSettled(blocked))
        #expect(run.capturedCount == 8)
        #expect(run.isCaptureComplete)
    }

    @Test func retriesLastUntilTheScreenIsCaptured() {
        let blocked = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        var run = AutopilotTestFixtures.run(.capture)
        run.problems = [AutopilotTestFixtures.problem(blocked, resolution: .retryWithFix)]
        #expect(run.retries.map(\.id) == ["pr-1"])
        #expect(run.remainingTargets.contains(blocked))

        run.captures = [AutopilotTestFixtures.capture(blocked)]
        #expect(run.retries.isEmpty)
    }

    @Test func anEmptyPlanIsNeverComplete() {
        var plan = AutopilotTestFixtures.smallPlan
        plan.screens = []
        #expect(!AutopilotTestFixtures.run(.capture, plan: plan).isCaptureComplete)
    }

    @Test func candidatesAreRankedByScoreThenEarliestAttempt() {
        var run = AutopilotTestFixtures.run(.pick)
        run.captures = [
            AutopilotTestFixtures.capture(today, attempt: 1, score: 0.6),
            AutopilotTestFixtures.capture(today, attempt: 2, score: 0.9),
            AutopilotTestFixtures.capture(today, attempt: 3, score: 0.9),
            AutopilotTestFixtures.capture(germanToday, attempt: 1, score: 1),
        ]
        #expect(run.candidates(for: "today").map(\.attempt) == [2, 3, 1], "German captures aren't candidates")
        #expect(run.pickedCapture(for: "today")?.attempt == 2, "The best, until the person picks")
        #expect(run.pickedCapture(for: "week") == nil)

        run.pickBest()
        #expect(run.picks == ["today": "cap-today-iphone-en-US-2"])
        run.picks["today"] = "cap-today-iphone-en-US-1"
        #expect(run.pickedCapture(for: "today")?.attempt == 1)
        run.picks["today"] = "cap-gone"
        #expect(run.pickedCapture(for: "today")?.attempt == 2, "A pick that's gone falls back to the best")
    }

    @Test func theSetUsesThePickedAttemptWhereEachLanguageHasIt() {
        let germanWeek = AutopilotTestFixtures.target("week", .iPhone, "de-DE")
        var run = AutopilotTestFixtures.run(.pick)
        run.captures = [
            AutopilotTestFixtures.capture(today, attempt: 1, score: 0.9),
            AutopilotTestFixtures.capture(today, attempt: 2, score: 0.7),
            AutopilotTestFixtures.capture(germanToday, attempt: 1, score: 0.95),
            AutopilotTestFixtures.capture(germanToday, attempt: 2, score: 0.5),
            AutopilotTestFixtures.capture(AutopilotTestFixtures.target("week"), attempt: 3, score: 0.8),
            AutopilotTestFixtures.capture(germanWeek, attempt: 1, score: 0.4),
        ]
        run.picks = ["today": "cap-today-iphone-en-US-2", "week": "cap-week-iphone-en-US-3"]
        #expect(run.finalCapture(for: germanToday)?.attempt == 2, "Attempt 2 was picked, and German has one")
        #expect(run.finalCapture(for: germanWeek)?.attempt == 1, "German has no attempt 3: its best")
        #expect(run.finalCapture(for: AutopilotTestFixtures.target("week", .iPad)) == nil)
    }

    @Test func directionsAndLanguagesChecked() {
        var run = StudioDebugRuns.run(.localize)
        #expect(run.hasAllDirections)
        #expect(run.chosenDirection?.id == "d-1")
        #expect(run.totalScreenshots == 120)
        #expect(run.checkedScreenshots == 60, "Six of twelve languages fit so far")

        run.chosenDirectionID = "d-9"
        run.directions.removeLast()
        #expect(run.chosenDirection == nil)
        #expect(!run.hasAllDirections)
    }

    @Test func theLogKeepsTheLatest400Lines() {
        var run = AutopilotTestFixtures.run(.capture)
        for index in 0..<405 {
            run.appendLog("line \(index)", kind: .event, at: AutopilotTestFixtures.now)
        }
        #expect(run.log.count == 400)
        #expect(run.log.first?.text == "line 5")
        #expect(run.log.last?.text == "line 404")
    }

    @Test(arguments: [
        (AutopilotStage.waiting, AutopilotStage.capture, 2, true),
        (.capture, .capture, 2, true),
        (.pick, .pick, 3, false),
        (.choose, .choose, 5, false),
        (.localize, .localize, 6, true),
        (.watchPreview, .watchPreview, 7, false),
        (.ready, .ready, 8, false),
    ])
    func stagesShowAsTheSheetsSteps(stage: AutopilotStage, step: AutopilotStage, number: Int, isRunning: Bool) {
        #expect(stage.step == step)
        #expect(stage.number == number)
        #expect(stage.isRunning == isRunning)
        #expect(stage.waitsForPerson == [.pick, .choose, .watchPreview].contains(stage))
    }
}
#endif
