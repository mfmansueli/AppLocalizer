//
//  ClaudeCodeHelperScriptTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The helper saved in the scripts folder: what `check` answers, its exit
/// line, and the script's own text.
@Suite("Claude Code helper script")
struct ClaudeCodeHelperScriptTests {
    @Test func checkFindsClaudeCodeAndShortensItsVersion() {
        let output = "helper 1\nclaude /Users/sam/.local/bin/claude\nversion 2.1.316 (Claude Code)\n"
        let installation = ClaudeCodeInstallation(path: "/Users/sam/.local/bin/claude", version: "2.1.316", helperVersion: 1)
        #expect(ClaudeCodeHelperScript.parseCheck(output) == .found(installation))
        #expect(installation.title == "Claude Code 2.1.316")
        #expect(installation.displayPath(home: "/Users/sam") == "~/.local/bin/claude")
    }

    @Test func checkWithoutAVersionStillFindsIt() {
        let result = ClaudeCodeHelperScript.parseCheck("helper 2\nclaude /opt/homebrew/bin/claude")
        #expect(result == .found(ClaudeCodeInstallation(path: "/opt/homebrew/bin/claude", version: "", helperVersion: 2)))
        #expect(ClaudeCodeInstallation(path: "", version: "", helperVersion: 2).title == "Claude Code")
    }

    @Test func checkSaysWhenClaudeCodeIsMissing() {
        #expect(ClaudeCodeHelperScript.parseCheck("helper 1\nclaude-missing") == .claudeMissing(helperVersion: 1))
    }

    @Test(arguments: ["", "zsh: permission denied", "claude /usr/bin/claude", "helper one\nclaude /x", "helper 1"])
    func anythingElseIsUnreadable(output: String) {
        #expect(ClaudeCodeHelperScript.parseCheck(output) == .unreadable)
    }

    @Test func theExitLineCarriesTheStatus() {
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit 0") == 0)
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit 143") == 143)
        #expect(ClaudeCodeHelperScript.exitStatus(in: #"{"type":"result"}"#) == nil)
        #expect(ClaudeCodeHelperScript.exitStatus(in: "applocalizer-helper-exit") == nil)
    }

    @Test func theScriptMatchesWhatTheAppExpects() {
        let script = ClaudeCodeHelperScript.contents
        #expect(script.hasPrefix("#!/bin/zsh"))
        #expect(script.contains("applocalizer-helper \(ClaudeCodeHelperScript.version)"))
        #expect(script.contains("helper_version=\(ClaudeCodeHelperScript.version)\n"))
        #expect(script.contains("\(ClaudeCodeHelperScript.exitMarker) $code"))
        #expect(script.contains("return \(ClaudeCodeRunFailure.claudeMissingStatus)"))
        #expect(script.contains("return \(ClaudeCodeRunFailure.folderMissingStatus)"))
        // Stop is a terminate: a background job ignores interrupts.
        #expect(script.contains("kill -TERM $pid"))
        #expect(ClaudeCodeHelperScript.fileName.hasSuffix(".zsh"))
    }
}
