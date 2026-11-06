//
//  ClaudeCodeToolUseTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// How Show Output describes each tool call.
@Suite("Claude Code tool use")
struct ClaudeCodeToolUseTests {
    private func describe(_ name: String, _ input: JSONValue? = nil) -> (ClaudeCodeToolUse.Kind, String) {
        ClaudeCodeToolUse.describe(name: name, input: input)
    }

    @Test func appLocalizersToolsGoByTheirOwnName() {
        let (kind, summary) = describe("mcp__applocalizer__suggest_fields", ["fields": []])
        #expect(kind == .appLocalizer)
        #expect(summary == "suggest_fields")
    }

    @Test func commandsShowTheirFirstLineShortened() {
        #expect(describe("Bash", ["command": "git log v1.3..HEAD --oneline\ngit status"]) == (.command, "git log v1.3..HEAD --oneline"))
        let long = String(repeating: "x", count: 300)
        let (_, summary) = describe("Bash", ["command": .string(long)])
        #expect(summary.count == 160)
        #expect(summary.hasSuffix("…"))
        #expect(describe("Bash") == (.command, "Bash"))
    }

    @Test func filesShowTheirName() {
        #expect(describe("Read", ["file_path": "/Users/sam/Developer/Lumen/CHANGELOG.md"]) == (.file, "Read CHANGELOG.md"))
        #expect(describe("Read") == (.file, "Read a file"))
        #expect(describe("Write", ["file_path": "/tmp/notes.txt"]) == (.file, "Write notes.txt"))
        #expect(describe("Edit") == (.file, "Edit"))
    }

    @Test func searches() {
        #expect(describe("Grep", ["pattern": "NSUserTrackingUsageDescription"]) == (.search, "Search for “NSUserTrackingUsageDescription”"))
        #expect(describe("Glob", ["pattern": "**/PrivacyInfo.xcprivacy"]) == (.search, "Find **/PrivacyInfo.xcprivacy"))
        #expect(describe("Glob") == (.search, "Find files"))
    }

    /// MB Admin's run card showed a regular expression as Claude Code's step.
    @Test func aRegularExpressionSaysWhereItSearches() {
        let pattern = #""startTime":[0-9.]+,"title":"(Added attachment named '[^']+'|Tap \"limpar fila)""#
        #expect(describe("Grep", ["pattern": .string(pattern), "path": "/Users/sam/MB-Admin/build/preview-ipad.json"])
            == (.search, "Search preview-ipad.json"))
        #expect(describe("Grep", ["pattern": .string(pattern), "glob": "*.swift"]) == (.search, "Search *.swift"))
        #expect(describe("Grep", ["pattern": "func launchApp|setUp"]) == (.search, "Search the project’s files"))
        #expect(describe("Grep", ["pattern": "XCUIDevice.shared.orientation"]) == (.search, "Search for “XCUIDevice.shared.orientation”"))
        #expect(describe("Grep") == (.search, "Search the project’s files"))
    }

    @Test func otherToolsKeepTheirName() {
        #expect(describe("mcp__github__create_pull_request") == (.other, "create_pull_request"))
        #expect(describe("TodoWrite") == (.other, "TodoWrite"))
    }

    @Test func aToolUseBecomesAnActivityOfItsKind() {
        let use = ClaudeCodeToolUse(id: "toolu_1", name: "Bash", input: ["command": "git tag"])
        let activity = ClaudeCodeActivity(id: 3, date: .distantPast, toolUse: use)
        #expect(activity.kind == .command)
        #expect(activity.text == "git tag")
        #expect(activity.toolUseID == "toolu_1")
        #expect(activity.systemImage == "terminal")
    }
}
