//
//  AutopilotPersistenceTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `Autopilot.json`: every app's run and design project, kept between
/// launches.
@MainActor
@Suite("Autopilot persistence")
struct AutopilotPersistenceTests {
    private let persistence = FileAutopilotPersistence(
        url: URL.temporaryDirectory.appending(path: "AutopilotPersistenceTests-\(UUID().uuidString)/Screenshots/Autopilot.json")
    )

    @Test func theArchiveRoundTripsEveryStage() throws {
        let runs = [StudioDebugRuns.failing, StudioDebugRuns.revised, StudioDebugRuns.run(.ready)]
        for run in runs {
            let archive = AutopilotArchive(runs: [run.appID: run], designProjects: [run.appID: StudioDebugRuns.northpier])
            persistence.save(archive)
            #expect(persistence.load() == archive)
        }
        let text = try String(contentsOf: persistence.url, encoding: .utf8)
        #expect(text.contains("\"uploadToken\":\"debug-token\""))
    }

    @Test func aMissingOrDamagedFileIsAnEmptyArchive() throws {
        #expect(persistence.load() == AutopilotArchive())
        persistence.save(AutopilotArchive())
        try Data("{ not json".utf8).write(to: persistence.url)
        #expect(persistence.load() == AutopilotArchive())
    }

    @Test func aCenterStartsFromTheArchiveAndSavesItsRuns() {
        let saved = StudioDebugRuns.run(.pick)
        persistence.save(AutopilotArchive(runs: [saved.appID: saved], designProjects: [saved.appID: StudioDebugRuns.northpier]))

        let center = AutopilotCenter(persistence: persistence)
        #expect(center.run(for: saved.appID) == saved)
        #expect(center.designProject(for: saved.appID) == StudioDebugRuns.northpier)
        // Picking: the upload link closed when capturing ended.
        #expect(center.run(uploadToken: "debug-token") == nil)

        let other = AutopilotTestFixtures.run(.capture)
        let given = AutopilotRun(
            id: "run-tempo", appID: "6450000003", versionString: "2.0", stage: .plan, plan: AutopilotTestFixtures.singlePlan(),
            designKind: .none, uploadToken: "token-tempo", createdAt: AutopilotTestFixtures.now
        )
        let merged = AutopilotCenter(persistence: persistence, runs: [other.appID: other, given.appID: given])
        #expect(merged.run(for: saved.appID) == other, "Runs handed to the center win over the archive's")
        merged.saveNow()
        #expect(persistence.load().runs == [other.appID: other, given.appID: given])
        #expect(persistence.load().designProjects == [saved.appID: StudioDebugRuns.northpier])
    }
}
#endif
