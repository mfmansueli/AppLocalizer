//
//  ClaudeCodeRunFailureTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// Why a run failed, from its result, the helper's status and stderr.
@Suite("Claude Code run failure")
struct ClaudeCodeRunFailureTests {
    private let folder = "/Users/sam/Developer/Lumen"

    private func classify(
        status: Int32?, result: ClaudeCodeResult? = nil, exit: UnixScriptExit = UnixScriptExit(), started: Bool = false
    ) -> ClaudeCodeRunFailure {
        ClaudeCodeRunFailure.classify(status: status, result: result, exit: exit, folder: folder, started: started)
    }

    @Test func anErrorResultSaysWhatClaudeCodeSaid() {
        let login = ClaudeCodeResult(isError: true, text: "Invalid API key · Please run /login")
        #expect(classify(status: 1, result: login) == .notLoggedIn("Invalid API key · Please run /login"))
        let other = ClaudeCodeResult(isError: true, text: "Reached the maximum number of turns")
        #expect(classify(status: 1, result: other) == .claudeError("Reached the maximum number of turns"))
    }

    @Test func theHelpersOwnStatuses() {
        #expect(classify(status: 127) == .claudeMissing)
        #expect(classify(status: 66) == .folderMissing(folder))
    }

    @Test func anyOtherStatusKeepsStderrsLastLine() {
        let exit = UnixScriptExit(errorOutput: "warming up\n  Error: something broke  \n", taskError: "status 1")
        #expect(classify(status: 1, exit: exit) == .exited(status: 1, message: "Error: something broke"))
        #expect(classify(status: 143) == .exited(status: 143, message: nil))
    }

    @Test func withoutAStatusTheHelperNeverRan() {
        #expect(classify(status: nil, exit: UnixScriptExit(taskError: "The file couldn’t be opened.")) == .couldNotStart("The file couldn’t be opened."))
        #expect(classify(status: nil, exit: UnixScriptExit(errorOutput: "zsh: permission denied")) == .couldNotStart("zsh: permission denied"))
        #expect(classify(status: nil) == .couldNotStart("The helper didn’t run."))
    }

    @Test func withoutAStatusAfterClaudeCodeStartedItEndedEarly() {
        let exit = UnixScriptExit(errorOutput: "Start Claude Code.zsh:111: write error: resource temporarily unavailable")
        let failure = classify(status: nil, exit: exit, started: true)
        #expect(failure == .exited(status: nil, message: "Start Claude Code.zsh:111: write error: resource temporarily unavailable"))
        #expect(failure.title == "Claude Code ended early")
        #expect(failure.detail.hasPrefix("It started, but its result didn’t reach AppLocalizer. It said: Start Claude Code.zsh:111"))
        #expect(classify(status: nil, started: true).detail == "It started, but its result didn’t reach AppLocalizer. Show Output has what it did.")
        // A status still wins.
        #expect(classify(status: 66, started: true) == .folderMissing(folder))
    }

    @Test func eachFailureOffersItsWayOut() {
        #expect(ClaudeCodeRunFailure.folderMissing(folder).needsFolder)
        #expect(!ClaudeCodeRunFailure.claudeMissing.needsFolder)
        #expect(ClaudeCodeRunFailure.notLoggedIn("x").suggestsTerminal)
        #expect(ClaudeCodeRunFailure.exited(status: 1, message: nil).suggestsTerminal)
        #expect(!ClaudeCodeRunFailure.folderMissing(folder).suggestsTerminal)
        #expect(!ClaudeCodeRunFailure.helperMissing.suggestsTerminal)
        #expect(ClaudeCodeRunFailure.folderMissing(folder).detail.contains("Lumen was moved or deleted"))
        #expect(ClaudeCodeRunFailure.exited(status: 2, message: nil).detail == "It ended with status 2 before it finished.")
        #expect(ClaudeCodeRunFailure.exited(status: 2, message: "boom").detail == "It said: boom (status 2).")
        #expect(ClaudeCodeRunFailure.claudeError("").detail == "Show Output has what it did before it stopped.")
    }
}
