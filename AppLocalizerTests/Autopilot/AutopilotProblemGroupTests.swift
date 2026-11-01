//
//  AutopilotProblemGroupTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// Problems with one cause become one card, and a fix that changes the
/// project is told apart from a command to run.
@MainActor
@Suite("Autopilot problem groups")
struct AutopilotProblemGroupTests {
    private static let projectFix = "In LumenUITests/ScreenshotTests.swift:64, tap app.buttons[\"journal.week\"]."

    private func problem(
        _ screen: String, _ display: ScreenshotDisplayType, _ locale: String, id: String, fix: String? = projectFix,
        changesProject: Bool? = nil, refused: String? = nil
    ) -> AutopilotProblem {
        var problem = AutopilotTestFixtures.problem(AutopilotTestFixtures.target(screen, display, locale), id: id, fix: fix, refused: refused)
        problem.changesProject = changesProject
        return problem
    }

    // MARK: - A change to the project

    @Test func aFixThatIsntACommandIsAChangeToTheProject() {
        #expect(problem("week", .iPhone, "ja", id: "1").needsProjectChange)
        #expect(!problem("week", .iPhone, "ja", id: "2", fix: "xcrun simctl privacy booted grant photos com.northpier.lumen").needsProjectChange)
        #expect(!problem("week", .iPhone, "ja", id: "3", fix: nil).needsProjectChange)
        #expect(!problem("week", .iPhone, "ja", id: "4", fix: "  ").needsProjectChange)
        #expect(problem("week", .iPhone, "ja", id: "5", fix: "xcrun simctl boot X\nthen edit the test").needsProjectChange, "Not one line")
    }

    @Test func theAssistantsWordComesFirstButARefusalAlwaysChangesTheProject() {
        #expect(problem("week", .iPhone, "ja", id: "1", fix: "xcrun simctl ui booted appearance light", changesProject: true).needsProjectChange)
        #expect(!problem("week", .iPhone, "ja", id: "2", changesProject: false).needsProjectChange)
        #expect(problem("week", .iPhone, "ja", id: "3", changesProject: false, refused: "LUMEN=1 xcodebuild test").needsProjectChange)
    }

    @Test func onlyACommandJoinsThePlan() {
        let command = "xcrun simctl privacy booted grant photos com.northpier.lumen"
        #expect(problem("week", .iPhone, "ja", id: "1", fix: command).fixIsCommand)
        #expect(!problem("week", .iPhone, "ja", id: "2").fixIsCommand, "A change to the project")
        let step = problem("week", .iPhoneDuo, "ko", id: "3", fix: "Install the iOS 27.1 simulator runtime, then retry.", changesProject: false)
        #expect(!step.needsProjectChange)
        #expect(!step.fixIsCommand, "A step for the person, though not a change to the project")
        #expect(!problem("week", .iPhone, "ja", id: "4", fix: nil).fixIsCommand)
        var device = problem("week", .iPhoneDuo, "ko", id: "5", fix: "xcodebuild -downloadPlatform iOS")
        device.affectsDevice = true
        #expect(!device.fixIsCommand, "A device-wide fix is the person's to start: it downloads several GB")
        #expect(!device.needsProjectChange)
    }

    @Test func aDeviceWideProblemIsOneGroupForTheDevice() throws {
        var first = problem("today", .iPhoneDuo, "en-US", id: "pr-1", fix: nil)
        var second = problem("week", .iPhoneDuo, "ko", id: "pr-2", fix: "Install the iOS simulator.")
        first.affectsDevice = true
        second.affectsDevice = true
        let groups = AutopilotProblemGroup.groups(of: [first, second, problem("week", .iPhone, "ko", id: "pr-3")])
        #expect(groups.map(\.id) == ["pr-1", "pr-3"])
        let device = try #require(groups.first)
        #expect(device.isDeviceWide)
        #expect(device.displayType == .iPhoneDuo)
        #expect(!device.fixIsCommand)
    }

    @Test func commandsStartWithAProgramASetupRuns() {
        #expect(AutopilotProblem.looksLikeCommand("xcodebuild test -scheme LumenScreenshots"))
        #expect(AutopilotProblem.looksLikeCommand("defaults write com.northpier.lumen onboarded -bool YES"))
        #expect(!AutopilotProblem.looksLikeCommand("Give the segment an accessibilityIdentifier"))
        #expect(!AutopilotProblem.looksLikeCommand("LUMEN=1 xcodebuild test"))
    }

    // MARK: - Groups

    @Test func problemsWithOneCauseOnOneScreenAreOneGroup() throws {
        let problems = [
            problem("week", .iPhone, "ja", id: "pr-1"),
            problem("today", .iPhone, "ja", id: "pr-2"),
            problem("week", .iPad, "ja", id: "pr-3"),
            problem("week", .iPhone, "de-DE", id: "pr-4", fix: "Use the scheme LumenScreenshots", changesProject: true),
            problem("week", .iPad, "de-DE", id: "pr-5", fix: "xcrun simctl privacy booted grant photos com.northpier.lumen"),
        ]
        let groups = AutopilotProblemGroup.groups(of: problems)
        #expect(groups.map(\.id) == ["pr-1", "pr-2", "pr-5"])

        let week = try #require(groups.first)
        #expect(week.problems.map(\.id) == ["pr-1", "pr-3", "pr-4"], "Every change to the project on one screen")
        #expect(week.screenID == "week")
        #expect(week.locales == ["ja", "de-DE"])
        #expect(week.displayTypes == [.iPhone, .iPad])
        #expect(week.needsProjectChange)
        #expect(week.proposedFix == Self.projectFix)
        #expect(!week.isSingle)
        #expect(week.includes(locale: "de-DE"))
        #expect(!week.includes(locale: "en-US"))

        #expect(groups[1].isSingle)
        #expect(!groups[2].needsProjectChange)
    }

    @Test func problemsWithoutAFixGroupByWhatHappened() {
        var first = problem("week", .iPhone, "ja", id: "pr-1", fix: nil)
        var second = problem("week", .iPad, "ja", id: "pr-2", fix: nil)
        var third = problem("week", .iPhone, "de-DE", id: "pr-3", fix: nil)
        first.what = "Blank"
        second.what = "Blank"
        third.what = "The keyboard covered it"
        #expect(AutopilotProblemGroup.groups(of: [first, second, third]).map(\.problems.count) == [2, 1])
    }

    @Test func aRefusedGroupKeepsItsCommand() {
        let group = AutopilotProblemGroup(problems: [
            problem("week", .iPhone, "ja", id: "pr-1"),
            problem("week", .iPad, "ja", id: "pr-2", refused: "LUMEN=1 xcodebuild test"),
        ])
        #expect(group.wasRefused)
        #expect(group.refusedCommand == "LUMEN=1 xcodebuild test")
    }

    @Test func theRunGroupsItsOpenProblems() {
        var run = AutopilotTestFixtures.run(.capture)
        run.problems = [
            problem("week", .iPhone, "de-DE", id: "pr-1"),
            problem("week", .iPad, "de-DE", id: "pr-2"),
            problem("today", .iPad, "de-DE", id: "pr-3", fix: nil),
        ]
        run.problems[2].resolution = .usePrimaryCapture
        #expect(run.problemGroups.map(\.id) == ["pr-1"])
        #expect(run.problemGroups.first?.problems.count == 2)
    }
}
#endif
