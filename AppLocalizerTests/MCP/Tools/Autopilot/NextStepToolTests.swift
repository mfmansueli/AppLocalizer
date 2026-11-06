//
//  NextStepToolTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `next_step` and the JSON of each answer: the action an assistant
/// switches on, and what it needs to do it.
@MainActor
@Suite("next_step")
struct NextStepToolTests {
    private static let tooLong = AutopilotOverflow(
        locale: "de-DE", slot: 2, displayType: .iPad, headline: "Durchsuche jahrelange Tagebucheinträge in Sekunden",
        subhead: "Alles an einem Ort", maxLines: 2, fill: 1.2345
    )
    private static let missing = AutopilotOverflow(locale: "th", slot: 0, displayType: .iPhone, headline: "", maxLines: 2, fill: 0)

    @Test func aWaitingRunIsPickedUpAndRehearsesFirst() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.waiting))
        let outcome = try await fixtures.call(NextStepTool(), ["run": "run-debug"])
        let rehearsal = try #require(StudioDebugRuns.plan.rehearsalLocale)
        #expect(AutopilotPlan.script(of: rehearsal) != "Latn")

        let result = outcome.result
        #expect(result["action"] == "capture")
        #expect(result["run"] == "run-debug")
        #expect(result["stage"] == "capture")
        #expect(result["remaining"] == 120)
        #expect(result["phase"] == "rehearsal")
        #expect(result["rehearsal"]?.stringValue?.contains("in en-US and \(rehearsal)") == true)
        let targets = try #require(result["targets"]?.arrayValue)
        #expect(targets.count == 20, "Five screens on two devices in two languages")
        #expect(Set(targets.compactMap { $0["locale"]?.stringValue }) == ["en-US", rehearsal])
        #expect(targets.first == ["screen": "today", "name": "Today", "displayType": "iphone", "locale": "en-US"])
        #expect(result["retryWithFix"] == [])
        #expect(result["how"]?.stringValue?.contains("report_capture_problem") == true)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · Autopilot", outcome: .read)])
        #expect(fixtures.run?.stage == .capture)
    }

    @Test func withoutARunTheAssistantIsToldWhereToStartOne() async throws {
        let outcome = try await MCPAutopilotFixtures().call(NextStepTool())
        #expect(outcome.result == [
            "action": "none",
            "say": "No Autopilot run is waiting. Ask the person to open AppLocalizer → Screenshots → Run Autopilot… and press Start Autopilot.",
        ])

        let planned = try await MCPAutopilotFixtures(AutopilotTestFixtures.run(.plan)).call(NextStepTool())
        #expect(planned.result["action"] == "none")
        #expect(planned.result["stage"] == "plan")
    }

    @Test func anOldRunIsTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture))
        await #expect(throws: MCPToolError.notFound("Run “run-0” is over; Lumen Journal’s current run is “run-1”. Call get_capture_plan.")) {
            try await fixtures.call(NextStepTool(), ["run": "run-0"])
        }
    }

    @Test func aRetryCarriesItsFix() async throws {
        var run = AutopilotTestFixtures.run(.capture)
        let target = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        AutopilotTestFixtures.captureAll(&run, except: [target])
        run.problems = [AutopilotTestFixtures.problem(target, resolution: .retryWithFix)]
        let result = try await MCPAutopilotFixtures(run).call(NextStepTool()).result

        #expect(result["remaining"] == 1)
        #expect(result["retryWithFix"] == [[
            "screen": "week", "displayType": "ipad", "locale": "de-DE", "fix": "xcrun simctl privacy booted grant photos com.northpier.lumen",
        ]])
    }

    @Test func afterTheRehearsalTheOtherLanguagesFollow() async throws {
        var run = StudioDebugRuns.run(.capture)
        run.captures = []
        let rehearsal = run.plan.rehearsalFirstTargets.filter(run.plan.isRehearsal)
        AutopilotTestFixtures.captureAll(&run, except: Set(run.plan.targets).subtracting(rehearsal))
        let result = try await MCPAutopilotFixtures(run).call(NextStepTool()).result

        #expect(result["phase"] == "capture")
        #expect(result["rehearsal"] == nil)
        #expect(result["remaining"] == 100)
        #expect(result["targets"]?.arrayValue?.count == 40)
        #expect(result["how"]?.stringValue?.contains("changesProject: true") == true)
    }

    @Test func oneLanguageHasNoPhase() async throws {
        let result = try await MCPAutopilotFixtures(AutopilotTestFixtures.run(.capture, plan: AutopilotTestFixtures.singlePlan())).call(NextStepTool()).result
        #expect(result["action"] == "capture")
        #expect(result["phase"] == nil)
    }

    @Test func aRetryAfterARefusalSaysNotToRunTheCommandAgain() async throws {
        var run = AutopilotTestFixtures.run(.capture)
        let target = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        AutopilotTestFixtures.captureAll(&run, except: [target])
        run.problems = [AutopilotTestFixtures.problem(
            target, fix: "Add a scheme that sets LUMEN_SCREENSHOTS=1.", refused: "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test",
            resolution: .retryWithFix
        )]
        let result = try await MCPAutopilotFixtures(run).call(NextStepTool()).result
        let retry = try #require(result["retryWithFix"]?.arrayValue?.first)
        #expect(retry["fix"] == "Add a scheme that sets LUMEN_SCREENSHOTS=1.")
        #expect(retry["refused"] == "TEST_RUNNER_LUMEN_SCREENSHOTS=1 xcodebuild test")
        #expect(retry["note"]?.stringValue?.contains("don't run the refused command") == true)
    }

    /// MB Admin's run stopped on a retry whose change wasn't made: Claude
    /// Code is told to report it again, so the person sees it, not a stall.
    @Test func aRetryThatChangesTheProjectIsReportedAgainWhenTheChangeIsMissing() async throws {
        var run = AutopilotTestFixtures.run(.capture)
        let target = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        AutopilotTestFixtures.captureAll(&run, except: [target])
        run.problems = [AutopilotTestFixtures.problem(
            target, fix: "In ScreenshotUITests.swift:12 rotate the iPad to landscape.", resolution: .retryWithFix
        )]
        let result = try await MCPAutopilotFixtures(run).call(NextStepTool()).result
        let retry = try #require(result["retryWithFix"]?.arrayValue?.first)
        #expect(retry["note"] == .string(AutopilotNextStep.projectChangeRetryNote))
        #expect(AutopilotNextStep.projectChangeRetryNote.contains("call report_capture_problem for this screen again"))

        // A command's retry needs no note.
        run.problems = [AutopilotTestFixtures.problem(target, resolution: .retryWithFix)]
        let command = try await MCPAutopilotFixtures(run).call(NextStepTool()).result
        #expect(command["retryWithFix"]?.arrayValue?.first?["note"] == nil)
    }

    // MARK: - JSON

    @Test(arguments: [
        (AutopilotNextStep.noRun, "none"),
        (.capture(targets: [], retries: []), "capture"),
        (.wait(reason: "The person is choosing a direction.", seconds: 20), "wait"),
        (.design(remaining: 2), "design"),
        (.revise(note: "Bigger headline"), "revise_direction"),
        (.writeCaptions([]), "write_captions"),
        (.done, "done"),
    ])
    func eachStepNamesItsAction(step: AutopilotNextStep, action: String) {
        #expect(step.mcpJSON(run: nil)["action"] == .string(action))
    }

    @Test func waitingDesigningAndRevisingSayWhatTheyNeed() throws {
        #expect(AutopilotNextStep.wait(reason: "The person is choosing a direction.", seconds: 20).mcpJSON(run: nil) == [
            "action": "wait", "reason": "The person is choosing a direction.", "retryAfterSeconds": 20,
        ])
        let design = AutopilotNextStep.design(remaining: 2).mcpJSON(run: nil)
        #expect(design["remaining"] == 2)
        let how = try #require(design["how"]?.stringValue)
        #expect(how.contains("get_design_brief") && how.contains("propose_direction"))
        let revise = AutopilotNextStep.revise(note: "Bigger headline").mcpJSON(run: nil)
        #expect(revise["note"] == "Bigger headline")
        #expect(revise["how"]?.stringValue?.contains("revise_direction") == true)
        #expect(AutopilotNextStep.done.mcpJSON(run: nil)["say"]?.stringValue?.contains("Nothing is uploaded until the person pushes") == true)
    }

    /// Board 32's note about the header and search: next_step shows each
    /// direction as it is now, which ones this note already changed, how
    /// the artwork's own look changes, and that the motion is fixed.
    @Test func revisingShowsEachDirectionAsItIsNow() throws {
        var run = StudioDebugArtMotion.revising
        run.revision?.revisedIDs = ["d-1"]
        let json = AutopilotNextStep.revise(note: "Warmer header and search images").mcpJSON(run: run)
        let directions = try #require(json["directions"]?.arrayValue)
        #expect(directions.count == 3)
        #expect(directions.map { $0["id"] } == ["d-1", "d-2", "d-3"])
        #expect(directions.map { $0["revisedForThisNote"] } == [true, false, false])
        #expect(directions[1]["template"] == run.directions[1].template.json)
        #expect(directions[1]["artwork"] == "follows template")
        #expect(directions[1]["appPreview"] == "follows template")
        let how = try #require(json["how"]?.stringValue)
        #expect(how.contains("last: false") && how.contains("every direction"))
        #expect(json["artwork"]?.stringValue?.contains("extrasTemplates.artwork") == true)
        #expect(json["motion"]?.stringValue?.contains("the page's own CSS animation") == true)
        #expect(json["motion"]?.stringValue?.contains("each cycle dividing 20 s") == true)

        var own = StudioDebugArtMotion.revising
        own.directions[0].artworkTemplate = ScreenshotTemplate.starter(.cinema, id: "lumen", title: "Lumen")
        let ownJSON = AutopilotNextStep.revise(note: "Warmer").mcpJSON(run: own)
        #expect(ownJSON["directions"]?.arrayValue?.first?["artwork"] == own.directions[0].artworkTemplate?.json)
    }

    @Test func aRunWithoutExtrasIsRevisedWithoutTheirNotes() {
        var run = StudioDebugRuns.run(.choose)
        run.stage = .design
        let json = AutopilotNextStep.revise(note: "Bigger headline").mcpJSON(run: run)
        #expect(json["directions"]?.arrayValue?.count == 3)
        #expect(json["directions"]?.arrayValue?.first?["artwork"] == nil)
        #expect(json["artwork"] == nil)
        #expect(json["motion"] == nil)
    }

    @Test func captionsToWriteSayWhetherTheyreMissingOrTooLong() throws {
        let json = AutopilotNextStep.writeCaptions([Self.tooLong, Self.missing]).mcpJSON(run: nil)
        #expect(json["captions"] == [
            [
                "locale": "de-DE", "slot": 3, "displayType": "ipad", "maxLines": 2, "problem": "too_long",
                "headline": "Durchsuche jahrelange Tagebucheinträge in Sekunden", "fill": .double(1.23), "subhead": "Alles an einem Ort",
            ],
            ["locale": "th", "slot": 1, "displayType": "iphone", "maxLines": 2, "problem": "missing"],
        ])
        let how = try #require(json["how"]?.stringValue)
        #expect(how.contains("measure_caption") && how.contains("propose_captions") && how.contains("as run"))
    }

    @Test func targetsAreNamedFromThePlanWhenThereIsOne() {
        let target = AutopilotTestFixtures.target("week", .iPad, "de-DE")
        let step = AutopilotNextStep.capture(targets: [target], retries: [AutopilotTestFixtures.problem(target, fix: nil)])
        let named = step.mcpJSON(run: AutopilotTestFixtures.run(.capture))
        #expect(named["targets"]?.arrayValue?.first?["name"] == "Week")
        #expect(named["retryWithFix"]?.arrayValue?.first?["fix"] == "")
        #expect(step.mcpJSON(run: nil)["targets"]?.arrayValue?.first?["name"] == "week")
    }
}
#endif
