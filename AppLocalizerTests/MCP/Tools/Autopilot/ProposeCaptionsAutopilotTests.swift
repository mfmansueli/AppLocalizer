//
//  ProposeCaptionsAutopilotTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// `propose_captions` with `run`: while an Autopilot run localizes, the
/// captions it asked for are saved right away instead of queued.
@MainActor
@Suite("propose_captions during Autopilot")
struct ProposeCaptionsAutopilotTests {
    /// Localizing in English and German, with German slot 3 too long.
    private var localizing: AutopilotRun {
        var run = StudioDebugRuns.run(.localize)
        run.plan.localeCodes = ["en-US", "de-DE"]
        run.shortenings = []
        let before = ScreenshotsTestFixtures.caption("de-DE", slot: 2)?.headline ?? ""
        run.overflows = [AutopilotOverflow(locale: "de-DE", slot: 2, displayType: .iPhone, headline: before, maxLines: 2, fill: 1.3)]
        return run
    }

    @Test func theRunsCaptionsAreSavedRightAway() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        let outcome = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "Shorter German.",
            "items": [["locale": "de", "slot": 3, "headline": "  Einträge aus Jahren finden  ", "subhead": " In Sekunden "]],
        ])

        #expect(outcome.result["status"] == "saved")
        #expect(outcome.result["saved"] == 1)
        #expect(outcome.result["captionsNotFitting"]?.intValue != nil)
        #expect(outcome.result["artworkTextsToWrite"]?.intValue != nil)
        #expect(outcome.result["next"]?.stringValue?.contains("Call next_step") == true)
        #expect(outcome.logLines == [.init(target: "Lumen Journal · de-DE · slot 3", outcome: .proposed)])
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        let saved = document.captions.caption(locale: "de-DE", slot: 2)
        #expect(saved?.headline == "Einträge aus Jahren finden")
        #expect(saved?.subhead == "In Sekunden")
        #expect(document.proposals == ScreenshotsDebugDocuments.standard.proposals, "Nothing is queued")
        #expect(fixtures.run?.shortenings.map(\.after) == ["Einträge aus Jahren finden"])
    }

    /// Bruma's run: 22 phrases still to translate read as 22 captions that
    /// didn't fit.
    @Test func whatsLeftIsSaidApart() {
        var run = localizing
        run.artworkTextNeeds = (0..<22).map { AutopilotArtworkTextNeed(locale: "de-DE", role: .header, problem: .missing, headline: "\($0)") }
        let left = ProposeCaptionsTool.savedResult(saved: 99, run: run)
        #expect(left["captionsNotFitting"] == 1)
        #expect(left["artworkTextsToWrite"] == 22)
        #expect(left["next"] == "Call next_step: it lists what’s still to write.")

        run.overflows = []
        run.artworkTextNeeds = nil
        let done = ProposeCaptionsTool.savedResult(saved: 3, run: run)
        #expect(done["captionsNotFitting"] == 0)
        #expect(done["artworkTextsToWrite"] == 0)
        #expect(done["next"]?.stringValue?.hasPrefix("Every caption and artwork text fits.") == true)
    }

    @Test(arguments: [
        ["locale": "de-DE", "slot": 9, "headline": "Hallo"] as JSONValue,
        ["locale": "de-DE", "slot": 0, "headline": "Hallo"],
        ["locale": "xx", "slot": 1, "headline": "Hallo"],
        ["locale": "de-DE", "slot": 1, "headline": "   "],
        ["locale": "th", "slot": 1, "headline": "สวัสดี"],
    ])
    func anItemOutsideThePlanIsRefused(item: JSONValue) async throws {
        let start = localizing
        let fixtures = MCPAutopilotFixtures(start)
        let outcome = try await fixtures.call(ProposeCaptionsTool(), ["run": "run-debug", "reason": "x", "items": [item]])
        #expect(outcome.result == ["status": "refused", "reason": "Each item needs a locale of the plan, a slot from 1 to 5 and a headline."])
        #expect(fixtures.run == start)
        let document = try await fixtures.services.document(for: AutopilotTestFixtures.app, primaryLocale: .englishUS)
        #expect(document.captions == ScreenshotsDebugDocuments.standard.captions, "Nothing is saved")
    }

    @Test func outsideLocalizeTheCaptionsAreRefused() async throws {
        let fixtures = MCPAutopilotFixtures(StudioDebugRuns.run(.choose))
        let outcome = try await fixtures.call(ProposeCaptionsTool(), [
            "run": "run-debug", "reason": "x", "items": [["locale": "de-DE", "slot": 1, "headline": "Hallo"]],
        ])
        #expect(outcome.result == [
            "status": "refused", "reason": "The run isn’t localizing now. Without run, propose_captions queues a proposal instead.",
        ])
    }

    @Test func anOldRunsCaptionsAreTurnedAway() async throws {
        let fixtures = MCPAutopilotFixtures(localizing)
        await #expect(throws: MCPToolError.notFound("Run “run-old” is over; Lumen Journal’s current run is “run-debug”. Call get_capture_plan.")) {
            try await fixtures.call(ProposeCaptionsTool(), [
                "run": "run-old", "reason": "x", "items": [["locale": "de-DE", "slot": 1, "headline": "Hallo"]],
            ])
        }
    }
}
#endif
