//
//  ClaudeCodeRunTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// A run's own story, as the status strips and Show Output read it.
@Suite("Claude Code run")
struct ClaudeCodeRunTests {
    private let start = Date(timeIntervalSince1970: 1_792_000_000)

    private func run(folder: String = "/Users/sam/Developer/Lumen") -> ClaudeCodeRun {
        ClaudeCodeRun(
            id: UUID(),
            appID: "6450000001",
            appName: "Lumen Journal",
            purpose: .suggestEverything,
            prompt: "Suggest everything",
            workingDirectory: folder,
            startedAt: start
        )
    }

    private func activity(_ kind: ClaudeCodeActivity.Kind, _ text: String, id: Int) -> ClaudeCodeActivity {
        ClaudeCodeActivity(id: id, date: start, kind: kind, text: text)
    }

    @Test func theLatestStepSkipsTheStartAndNamesAppLocalizer() {
        var run = run()
        #expect(run.latestStep == nil)
        run.activity = [activity(.started, "Claude Code 2.1.316 started", id: 1)]
        #expect(run.latestStep == nil)
        run.activity.append(activity(.appLocalizer, "get_store_page", id: 2))
        #expect(run.latestStep == "AppLocalizer · get_store_page")
        run.activity.append(activity(.file, "Read CHANGELOG.md", id: 3))
        #expect(run.latestStep == "Read CHANGELOG.md")
    }

    @Test func theStatusFollowsThePhase() {
        var run = run(folder: "/Users/sam/Developer/Lumen")
        #expect(run.isActive)
        #expect(run.statusTitle.hasPrefix("Starting Claude Code in "))
        run.phase = .working
        #expect(run.statusTitle.hasPrefix("Working in "))
        run.phase = .finished
        #expect(!run.isActive)
        #expect(run.statusTitle == "Finished")
        let denials = [ClaudeCodeResult.Denial(toolName: "Bash", summary: "swift build"), .init(toolName: "Edit", summary: "Edit a.swift")]
        run.result = ClaudeCodeResult(isError: false, text: "Done.", denials: denials)
        #expect(run.statusTitle == "Finished · 2 steps weren’t allowed")
        run.phase = .failed(.claudeMissing)
        #expect(run.failure == .claudeMissing)
        #expect(run.statusTitle == ClaudeCodeRunFailure.claudeMissing.title)
    }

    @Test func theTimelineDropsClosingWordsTheResultRepeats() {
        var run = run()
        run.activity = [activity(.appLocalizer, "list_apps", id: 1), activity(.said, "You have 6 apps.", id: 2)]
        #expect(run.timeline == run.activity)
        run.result = ClaudeCodeResult(isError: false, text: "You have 6 apps.")
        #expect(run.timeline.map(\.id) == [1])

        // Shortened words still match the full result.
        run.activity[1].text = "You have 6…"
        #expect(run.timeline.map(\.id) == [1])

        run.result = ClaudeCodeResult(isError: false, text: "Something else.")
        #expect(run.timeline.map(\.id) == [1, 2])
        run.result = ClaudeCodeResult(isError: false, text: "")
        #expect(run.timeline.map(\.id) == [1, 2])
    }

    @Test func resumeNeedsASessionAndQuotesTheFolder() {
        var run = run(folder: "/Users/sam/Sam's Apps/Lumen")
        #expect(run.resumeCommand == nil)
        run.sessionID = "abc"
        #expect(run.resumeCommand == "cd '/Users/sam/Sam'\\''s Apps/Lumen' && claude --resume abc")
    }

    @Test @MainActor func elapsedStopsWhenItEnds() {
        var run = run()
        #expect(run.elapsed(at: start.addingTimeInterval(90)) == 90)
        run.endedAt = start.addingTimeInterval(30)
        #expect(run.elapsed(at: start.addingTimeInterval(90)) == 30)
        #expect(ClaudeCodeRunStatusView.duration(65) == "1:05")
        #expect(ClaudeCodeRunStatusView.duration(3725) == "1:02:05")
    }
}
