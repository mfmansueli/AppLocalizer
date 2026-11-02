//
//  ClaudeCodePermissionsTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// What each kind of run may do: AppLocalizer's tools always, reading the
/// project for suggestions, and building and simulators for Autopilot only.
@Suite("Claude Code permissions")
struct ClaudeCodePermissionsTests {
    private let port: UInt16 = 47321

    @Test func eachPurposePicksItsPermissions() {
        #expect(ClaudeCodeRunPurpose.test.permissions == .appLocalizerOnly)
        #expect(ClaudeCodeRunPurpose.autopilot.permissions == .autopilot)
        let reading: [ClaudeCodeRunPurpose] = [.ask(area: "Store Page"), .suggestEverything, .translation, .captions, .privacyScan]
        for purpose in reading {
            #expect(purpose.permissions == .readProject, "\(purpose.title)")
        }
        #expect(ClaudeCodeRunPurpose.ask(area: "Store Page").title == "Ask · Store Page")
    }

    @Test func theSetupTestOnlyUsesAppLocalizer() {
        #expect(ClaudeCodePermissions.appLocalizerOnly.tools.isEmpty)
        #expect(ClaudeCodePermissions.appLocalizerOnly.allowRules(port: port) == ["mcp__applocalizer"])
    }

    @Test func readingTheProjectAllowsOnlyReadOnlyGit() {
        let rules = ClaudeCodePermissions.readProject.allowRules(port: port)
        #expect(rules.contains("mcp__applocalizer"))
        #expect(rules.contains("Read"))
        #expect(rules.contains("Bash(git log:*)"))
        let commands = rules.filter { $0.hasPrefix("Bash(") }
        #expect(commands.allSatisfy { $0.hasPrefix("Bash(git ") }, "\(commands)")
        for writing in ["push", "commit", "reset", "checkout", "config"] {
            #expect(!rules.contains("Bash(git \(writing):*)"))
        }
    }

    @Test func autopilotAlsoBuildsAndUploadsOnlyToAppLocalizer() {
        let rules = ClaudeCodePermissions.autopilot.allowRules(port: port)
        #expect(rules.contains("Bash(xcodebuild:*)"))
        #expect(rules.contains("Bash(xcrun simctl:*)"))
        let uploads = rules.filter { $0.contains("curl") }
        #expect(uploads == ["Bash(curl * http://127.0.0.1:47321/autopilot/*)"])
        #expect(ClaudeCodePermissions.autopilot.systemPrompt.contains("curl -s --data-binary"))
    }

    /// `VAR=value xcodebuild …` doesn't match `Bash(xcodebuild:*)`, so
    /// Autopilot is told so, how UI tests get their language instead, and
    /// how to report a refusal.
    @Test func autopilotKnowsWhatGetsRefused() {
        let prompt = ClaudeCodePermissions.autopilot.systemPrompt
        #expect(prompt.contains("VAR=value in front of it, cd or a pipe is refused"))
        #expect(prompt.contains("testArguments (-testLanguage, -testRegion)"))
        #expect(prompt.contains("report_capture_problem with refusedCommand"))
    }

    /// Changing a simulator's displays (`simctl io … screenConfig`) left
    /// iPhone Duo's SpringBoard crashing on every start, so Autopilot may run
    /// any simctl command but that one, and the other runs deny nothing
    /// they could run anyway.
    @Test func autopilotMayNotChangeASimulatorsDisplays() {
        #expect(ClaudeCodePermissions.autopilot.denyRules == ["Bash(xcrun simctl io * screenConfig*)"])
        #expect(ClaudeCodePermissions.appLocalizerOnly.denyRules.isEmpty)
        #expect(ClaudeCodePermissions.readProject.denyRules.isEmpty)
        let how = AutopilotRun.howToCapture(.iPhoneDuo) ?? ""
        #expect(how.contains("Never change its displays with xcrun simctl io … screenConfig"))
    }

    @Test func noRunMayEditFilesOrUseTheWeb() {
        for permissions in ClaudeCodePermissions.allCases {
            let everything = permissions.tools + permissions.allowRules(port: port)
            for tool in ["Edit", "Write", "NotebookEdit", "WebFetch", "WebSearch"] {
                #expect(!everything.contains(tool), "\(permissions.title) allows \(tool)")
            }
            // Bash is available to some, but only for the commands allowed.
            #expect(!permissions.allowRules(port: port).contains("Bash"), "\(permissions.title) allows every command")
        }
    }

    @Test func theSystemPromptSaysNobodyIsWatching() {
        for permissions in ClaudeCodePermissions.allCases {
            let prompt = permissions.systemPrompt
            #expect(prompt.contains("don't ask questions"))
            #expect(prompt.contains("Never push"))
        }
        #expect(!ClaudeCodePermissions.readProject.systemPrompt.contains("xcodebuild"))
    }
}
