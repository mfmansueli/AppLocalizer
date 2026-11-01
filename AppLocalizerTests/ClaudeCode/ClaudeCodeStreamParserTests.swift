//
//  ClaudeCodeStreamParserTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

/// Reading `claude -p --output-format stream-json --verbose` line by line.
@Suite("Claude Code stream parser")
struct ClaudeCodeStreamParserTests {
    private typealias Lines = ClaudeCodeTestFixtures

    @Test func initStartsTheSession() {
        let events = ClaudeCodeStreamParser.events(in: Lines.initLine())
        #expect(events == [.started(sessionID: Lines.sessionID, model: "claude-opus-5-5", version: "2.1.316", failedServers: [])])
    }

    @Test func initNamesServersThatDidntConnect() {
        let events = ClaudeCodeStreamParser.events(in: Lines.initLine(serverStatus: "failed"))
        #expect(events == [.started(sessionID: Lines.sessionID, model: "claude-opus-5-5", version: "2.1.316", failedServers: ["applocalizer"])])
    }

    @Test func assistantMessagesGiveWordsAndToolCalls() {
        #expect(ClaudeCodeStreamParser.events(in: Lines.saidLine("  Reading the changelog.  ")) == [.said("Reading the changelog.")])
        let events = ClaudeCodeStreamParser.events(in: Lines.toolUseLine("mcp__applocalizer__get_listing", id: "toolu_1"))
        #expect(events == [.usedTool(ClaudeCodeToolUse(id: "toolu_1", name: "mcp__applocalizer__get_listing", input: [:]))])
    }

    @Test func emptyTextAndThinkingAreSkipped() {
        let line = #"""
        {"type":"assistant","message":{"content":[{"type":"thinking","thinking":"","signature":"x"},{"type":"text","text":" \n"}]}}
        """#
        #expect(ClaudeCodeStreamParser.events(in: line).isEmpty)
    }

    @Test func failedToolResultsAreReportedOthersArent() {
        #expect(ClaudeCodeStreamParser.events(in: Lines.toolErrorLine("toolu_2", message: "Permission denied")) == [
            .toolFailed(toolUseID: "toolu_2", message: "Permission denied"),
        ])
        let fine = #"{"type":"user","message":{"content":[{"tool_use_id":"toolu_3","type":"tool_result","content":"ok"}]}}"#
        #expect(ClaudeCodeStreamParser.events(in: fine).isEmpty)
        let blocks = #"""
        {"type":"user","message":{"content":[{"tool_use_id":"t4","type":"tool_result","is_error":true,"content":[{"type":"text","text":"No such file"}]}]}}
        """#
        #expect(ClaudeCodeStreamParser.events(in: blocks) == [.toolFailed(toolUseID: "t4", message: "No such file")])
    }

    @Test func theResultEndsTheRun() {
        let events = ClaudeCodeStreamParser.events(in: Lines.resultLine(text: "Sent 3 suggestions."))
        guard case let .finished(result)? = events.first else {
            Issue.record("Expected a result, got \(events)")
            return
        }
        #expect(!result.isError)
        #expect(result.text == "Sent 3 suggestions.")
        #expect(result.sessionID == Lines.sessionID)
        #expect(result.subtype == "success")
        #expect(result.turns == 3)
        #expect(result.duration == .milliseconds(8123))
        #expect(result.apiErrorStatus == nil)
        #expect(result.denials.isEmpty)
        #expect(!result.isLoginProblem)
    }

    @Test func refusedCallsAreListed() {
        let denials = #"""
        [{"tool_name":"Bash","tool_use_id":"d1","tool_input":{"command":"swift package resolve"}},\#
        {"tool_name":"Edit","tool_use_id":"d2","tool_input":{"file_path":"/Users/sam/Developer/Lumen/Info.plist"}}]
        """#
        let events = ClaudeCodeStreamParser.events(in: Lines.resultLine(text: "Done.", denials: denials))
        guard case let .finished(result)? = events.first else {
            Issue.record("Expected a result, got \(events)")
            return
        }
        #expect(result.denials == [
            ClaudeCodeResult.Denial(toolName: "Bash", summary: "swift package resolve"),
            ClaudeCodeResult.Denial(toolName: "Edit", summary: "Edit Info.plist"),
        ])
    }

    @Test(arguments: [
        (#"{"type":"result","is_error":true,"result":"Invalid API key · Please run /login","api_error_status":null}"#, true),
        (#"{"type":"result","is_error":true,"result":"Request failed","api_error_status":401}"#, true),
        (#"{"type":"result","is_error":true,"result":"Not logged in · Please run /login"}"#, true),
        (#"{"type":"result","is_error":true,"result":"Reached the maximum number of turns"}"#, false),
        (#"{"type":"result","is_error":false,"result":"How to /login, explained"}"#, false),
    ])
    func loginProblemsAreRecognized(line: String, isLogin: Bool) {
        guard case let .finished(result)? = ClaudeCodeStreamParser.events(in: line).first else {
            Issue.record("Expected a result")
            return
        }
        #expect(result.isLoginProblem == isLogin)
    }

    @Test func withoutIsErrorTheSubtypeDecides() {
        let line = #"{"type":"result","subtype":"error_max_turns","result":""}"#
        guard case let .finished(result)? = ClaudeCodeStreamParser.events(in: line).first else {
            Issue.record("Expected a result")
            return
        }
        #expect(result.isError)
    }

    @Test(arguments: [
        "applocalizer-helper-exit 0",
        "",
        "{not json",
        #"{"type":"rate_limit_event","rate_limit_info":{}}"#,
        #"{"type":"system","subtype":"hook_started"}"#,
        #"{"type":"stream_event","event":{}}"#,
    ])
    func otherLinesSayNothing(line: String) {
        #expect(ClaudeCodeStreamParser.events(in: line).isEmpty)
    }
}
