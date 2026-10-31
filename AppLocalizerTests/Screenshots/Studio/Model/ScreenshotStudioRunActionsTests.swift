//
//  ScreenshotStudioRunActionsTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// The Autopilot sheet's actions once a run is going: a problem's
/// answers, picks, directions, Ask for Changes and See the Preview. The
/// center holds its stages, so each action moves the run one step.
@MainActor
@Suite("ScreenshotStudioModel · Run")
struct ScreenshotStudioRunActionsTests {
    private var appID: StoreApp.ID { StudioTestFixtures.app.id }

    // MARK: - Capture

    @Test func retryingWithTheFixAddsItToThePlan() async throws {
        let center = StudioTestFixtures.center(Self.blocked)
        let model = await StudioTestFixtures.screenshots(center: center)
        let problem = try #require(center.run(for: appID)?.problems.first)
        let fix = try #require(problem.proposedFix)
        model.studio.resolve(problem, with: .retryWithFix)
        #expect(await ScreenshotsTestWaiting.until { center.run(for: appID)?.openProblems.isEmpty == true })
        let run = try #require(center.run(for: appID))
        #expect(run.problems.first?.resolution == .retryWithFix)
        #expect(run.plan.simulator.extraCommands.contains(fix))
        #expect(run.retries.map(\.id) == [problem.id])
        #expect(!run.isSettled(problem.target))
    }

    @Test func usingThePrimaryCaptureSettlesTheScreen() async throws {
        let center = StudioTestFixtures.center(Self.blocked)
        let model = await StudioTestFixtures.screenshots(center: center)
        let problem = try #require(center.run(for: appID)?.problems.first)
        #expect(center.run(for: appID)?.isSettled(problem.target) == false)
        model.studio.resolve(problem, with: .usePrimaryCapture)
        #expect(await ScreenshotsTestWaiting.until { center.run(for: appID)?.problems.first?.resolution == .usePrimaryCapture })
        let run = try #require(center.run(for: appID))
        #expect(run.isSettled(problem.target))
        #expect(run.retries.isEmpty)
        #expect(run.plan.simulator.extraCommands.isEmpty)
    }

    @Test func aPNGUploadedByHandBecomesTheScreensCapture() async throws {
        let center = StudioTestFixtures.center(Self.blocked)
        let model = await StudioTestFixtures.screenshots(center: center)
        let problem = try #require(center.run(for: appID)?.problems.first)
        let size = problem.target.displayType.portraitPixelSize
        let image = try #require(FakeScreenshotsServices.flatImage(width: size.width, height: size.height))
        let png = try #require(ScreenshotPNG.data(image))
        let url = try Self.write(png, name: "photos.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        await model.studio.upload(url, for: problem)
        let run = try #require(center.run(for: appID))
        let captures = run.captures(for: problem.target)
        #expect(captures.count == 1)
        let capture = try #require(captures.first)
        #expect(capture.notes == "Uploaded by hand")
        #expect(capture.pixelSize == size)
        #expect(run.problems.first?.resolution == .uploadedByHand)
        #expect(model.notice == nil)
    }

    @Test func aFileThatIsntAPNGSaysSo() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.failing)
        let model = await StudioTestFixtures.screenshots(center: center)
        let problem = try #require(center.run(for: appID)?.problems.first)
        let url = try Self.write(Data("not a picture".utf8), name: "notes.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        await model.studio.upload(url, for: problem)
        #expect(model.notice == "That isn’t a PNG. Send the screenshot file’s bytes.")
        #expect(center.run(for: appID)?.openProblems.count == 1)
    }

    // MARK: - Pick

    @Test func pickingAnotherCaptureReplacesTheAssistantsPick() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.pick))
        let model = await StudioTestFixtures.screenshots(center: center)
        let run = try #require(center.run(for: appID))
        let screen = try #require(run.plan.screens.first)
        let candidates = run.candidates(for: screen.id)
        #expect(candidates.count == 3)
        #expect(model.studio.pickedCaptures.first??.id == candidates[0].id)
        model.studio.pick(candidates[1], for: screen.id)
        #expect(model.studio.pickedCaptures.first??.id == candidates[1].id)
        #expect(model.studio.pickedCaptures.count == run.plan.screens.count)
    }

    @Test func usingThePicksMovesOnToDesign() async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.pick))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.viewedStep = .capture
        model.studio.usePicks()
        #expect(model.studio.viewedStep == nil)
        #expect(await ScreenshotsTestWaiting.until { center.run(for: appID)?.stage == .design })
    }

    // MARK: - Choose

    @Test func usingADirectionStartsLocalizing() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.choose))
        let model = await StudioTestFixtures.screenshots(center: center)
        let direction = try #require(center.run(for: appID)?.directions.last)
        model.studio.viewedStep = .design
        model.studio.useDirection(direction)
        #expect(model.studio.viewedStep == nil)
        #expect(await ScreenshotsTestWaiting.until { center.run(for: appID)?.stage == .localize })
        #expect(center.run(for: appID)?.chosenDirection?.name == "Dawn Panorama")
    }

    @Test func askingForChangesSendsTheNoteToTheDesignAI() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.choose))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.revisionNote = "  Bigger headline, lighter indigo  "
        model.studio.viewedStep = .pick
        model.studio.askForChanges()
        let run = try #require(center.run(for: appID))
        #expect(run.stage == .design)
        #expect(run.revision?.note == "Bigger headline, lighter indigo")
        #expect(run.revision?.askedAt == StudioTestFixtures.now)
        #expect(model.studio.revisionNote.isEmpty)
        #expect(model.studio.viewedStep == nil)
    }

    @Test(arguments: [(true, "   "), (false, "Bigger headline")])
    func askingForNothingOrOfTheStartersKeepsChoosing(design: Bool, note: String) async {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.choose, design: design))
        let model = await StudioTestFixtures.screenshots(center: center)
        model.studio.revisionNote = note
        model.studio.askForChanges()
        #expect(center.run(for: appID)?.stage == .choose)
        #expect(center.run(for: appID)?.revision == nil)
        #expect(model.studio.revisionNote.isEmpty)
    }

    @Test func aDirectionsLayoutsAreTheScreensInThePrimaryLanguage() async throws {
        let center = StudioTestFixtures.center(StudioDebugRuns.run(.choose))
        let model = await StudioTestFixtures.screenshots(center: center)
        let direction = try #require(center.run(for: appID)?.directions.first)
        let layouts = model.studio.layouts(for: direction)
        #expect(layouts.count == 5)
        #expect(layouts.allSatisfy { $0.locale == "en-US" && $0.canvas.display == .iPhone })
        #expect(model.studio.directionLayouts.count == 1)
        #expect(model.studio.layouts(for: direction) == layouts)
        #expect(model.studio.directionLayouts.count == 1)
    }

    // MARK: - Ready

    @Test func seeThePreviewClosesTheSheetOnTheNewSet() async {
        let model = await StudioTestFixtures.screenshots(center: StudioTestFixtures.center(StudioDebugRuns.run(.ready)))
        model.studio.isAutopilotPresented = true
        model.studio.seePreview()
        #expect(!model.studio.isAutopilotPresented)
        #expect(await ScreenshotsTestWaiting.until { model.studio.choice == .new })
    }

    // MARK: - Helpers

    /// Capturing, with the German photo entry blocked and not captured.
    private static var blocked: AutopilotRun {
        var run = StudioDebugRuns.failing
        let targets = Set(run.problems.map(\.target))
        run.captures.removeAll { targets.contains($0.target) }
        return run
    }

    private static func write(_ data: Data, name: String) throws -> URL {
        let folder = URL.temporaryDirectory.appending(path: "AppLocalizerTests-Studio-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: name)
        try data.write(to: url)
        return url
    }
}
#endif
