//
//  AutopilotStallWordingTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// What the sheet says when nobody works on a run, in the stage's words:
/// captures at Capture, directions or the asked changes at Design. Only a
/// stop or a silence is a warning; a pause, or Claude Code's turn, isn't.
@MainActor
@Suite("Autopilot stall wording")
struct AutopilotStallWordingTests {
    private static let now = AutopilotTestFixtures.now

    @Test func captureCountsTheCapturesLeft() {
        var run = AutopilotTestFixtures.run(.capture)
        let left = run.capturesLeft
        #expect(AutopilotStall.ended(lastWords: nil).headline(of: run, now: Self.now) == "Claude Code stopped with \(left) captures left.")
        #expect(AutopilotStall.ended(lastWords: nil).footer(of: run)
            == "Claude Code isn’t working on this run, with \(left) captures left. Continue picks it up where it stopped.")
        AutopilotTestFixtures.captureAll(&run, except: [AutopilotTestFixtures.target("week")])
        #expect(AutopilotStall.workLeft(in: run) == "1 capture left")
        #expect(AutopilotStall.continueNote(for: run).contains("what’s captured stays"))
    }

    /// The paused Design of the screenshot: one direction in, two to go.
    @Test func designCountsTheDirectionsLeft() {
        var run = StudioDebugRuns.run(.design)
        #expect(AutopilotStall.notRunning.headline(of: run, now: Self.now) == "Paused when AppLocalizer closed, with 2 directions still to design.")
        #expect(AutopilotStall.notRunning.footer(of: run)
            == "Paused when AppLocalizer closed, with 2 directions still to design. Continue picks it up where it is.")
        #expect(AutopilotStall.ended(lastWords: nil).headline(of: run, now: Self.now) == "Claude Code stopped with 2 directions still to design.")
        #expect(AutopilotStall.handedBack.headline(of: run, now: Self.now) == "It’s Claude Code’s turn again, with 2 directions still to design.")
        #expect(AutopilotStall.continueNote(for: run) == "Continue starts Claude Code again where the run is: the directions that arrived stay.")

        run.directions = Array(StudioDebugRuns.directions(design: true, of: run).prefix(2))
        #expect(AutopilotStall.workLeft(in: run) == "1 direction still to design")
        run.revision = AutopilotRevisionRequest(note: "Bigger headline", askedAt: Self.now)
        #expect(AutopilotStall.ended(lastWords: nil).headline(of: run, now: Self.now) == "Claude Code stopped with your changes still to make.")
    }

    @Test func localizeCountsTheCaptionsLeft() {
        let run = StudioDebugRuns.writingCaptions
        #expect(AutopilotStall.notRunning.headline(of: run, now: Self.now) == "Paused when AppLocalizer closed, with 11 captions still to write.")
        #expect(AutopilotStall.continueNote(for: run).hasSuffix("it writes the captions that are missing or too long."))
    }

    @Test func aSilenceCountsItsMinutes() {
        let run = StudioDebugRuns.run(.design)
        let headline = AutopilotStall.quiet(since: Self.now).headline(of: run, now: Self.now.addingTimeInterval(45 * 60))
        #expect(headline == "Nothing has arrived for 45 minutes, with 2 directions still to design. If Claude Code stopped, continue it here.")
    }

    @Test func onlyAStopOrASilenceLooksLikeAProblem() {
        #expect(AutopilotStall.ended(lastWords: nil).isWarning)
        #expect(AutopilotStall.quiet(since: Self.now).isWarning)
        #expect(!AutopilotStall.notRunning.isWarning)
        #expect(!AutopilotStall.handedBack.isWarning)
        #expect(AutopilotStall.ended(lastWords: "Done.").stageNote == "Claude Code stopped")
        #expect(AutopilotStall.quiet(since: Self.now).stageNote == "Nothing new for a while")
        #expect(AutopilotStall.notRunning.stageNote == "Paused · Continue picks it up")
        #expect(AutopilotStall.handedBack.stageNote == nil)
    }

    /// A guided run without a design project: the starters are in, the
    /// assistant's headers aren't.
    @Test func onlyHeadersLeftAreCountedAsHeaders() {
        var run = StudioDebugHeaderStyle.headerOnly(.design, style: .free)
        run.concepts = nil
        #expect(run.directionsLeft == 0)
        #expect(AutopilotStall.notRunning.headline(of: run, now: Self.now) == "Paused when AppLocalizer closed, with 3 headers still to design.")
    }
}
#endif
