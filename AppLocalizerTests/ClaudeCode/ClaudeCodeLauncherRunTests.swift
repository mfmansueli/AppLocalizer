//
//  ClaudeCodeLauncherRunTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Runs through the pretend helper: what they pass Claude Code, how their
/// stream becomes a story, how they end, and their token's lifetime.
@MainActor
@Suite("ClaudeCodeLauncher · runs")
struct ClaudeCodeLauncherRunTests {
    private typealias Lines = ClaudeCodeTestFixtures
    private let clock = TestClock()
    private let server = FakeLocalHTTPServer()
    private let assistants: MCPServerController
    private let runner = FakeUnixScriptRunner()
    private let launcher: ClaudeCodeLauncher

    init() {
        assistants = MCPTestFixtures.controller(server: server, clock: clock)
        launcher = ClaudeCodeTestFixtures.launcher(assistants: assistants, runner: runner, clock: clock)
        launcher.setProjectFolder(ClaudeCodeTestFixtures.lumenFolder, for: ClaudeCodeTestFixtures.lumenID)
    }

    private func start(_ purpose: ClaudeCodeRunPurpose = .suggestEverything, prompt: String = "Suggest everything") async throws -> ClaudeCodeRun.ID {
        await launcher.refreshHelper()
        return try #require(await launcher.start(purpose, appID: ClaudeCodeTestFixtures.lumenID, appName: "Lumen Journal", prompt: prompt))
    }

    private func finishedRun(_ id: ClaudeCodeRun.ID) async throws -> ClaudeCodeRun {
        await ClaudeCodeTestFixtures.waitForEnd(of: id, in: launcher)
        let run = try #require(launcher.run(id))
        #expect(!run.isActive)
        return run
    }

    /// The `--mcp-config` the last run got.
    private func runToken() throws -> String {
        let arguments = try #require(runner.lastRunArguments)
        let index = try #require(arguments.firstIndex(of: "--mcp-config"))
        let configuration = try JSONDecoder().decode(JSONValue.self, from: Data(arguments[index + 1].utf8))
        let header = try #require(configuration["mcpServers"]?["applocalizer"]?["headers"]?["Authorization"]?.stringValue)
        return String(header.dropFirst("Bearer ".count))
    }

    @Test func aRunActsAsThePairedClaudeCodeWithItsOwnToken() async throws {
        runner.exitStatus = nil
        let id = try await start()
        await ClaudeCodeTestFixtures.waitForHelper(runner)

        #expect(assistants.isEnabled)
        #expect(server.startedPorts == [assistants.port])
        let client = try #require(assistants.pairedClients.first)
        #expect(assistants.pairedClients.count == 1)
        #expect(client.kind == .claudeCode)

        let token = try runToken()
        #expect(token != assistants.tokens[client.id])
        #expect(assistants.runTokens[token] == client.id)
        #expect(assistants.authorizedClientID(for: "Bearer \(token)") == client.id)

        let arguments = try #require(runner.lastRunArguments)
        #expect(arguments.contains("AppLocalizer · Suggest Everything · Lumen Journal"))
        #expect(arguments.contains("Suggest everything"))

        launcher.stop(id)
        _ = try await finishedRun(id)
        #expect(assistants.runTokens.isEmpty)
        #expect(assistants.authorizedClientID(for: "Bearer \(token)") == nil)
        #expect(assistants.pairedClients.map(\.id) == [client.id])
    }

    @Test func theStreamBecomesTheRunsStory() async throws {
        runner.lines = [
            Lines.initLine(),
            Lines.toolUseLine("mcp__applocalizer__get_store_page", id: "t1"),
            Lines.toolUseLine("Read", id: "t2", input: #"{"file_path":"/Users/sam/Developer/Lumen/CHANGELOG.md"}"#),
            Lines.toolErrorLine("t2", message: "File does not exist.\\nTry another path."),
            Lines.toolUseLine("mcp__applocalizer__suggest_fields", id: "t3"),
            Lines.saidLine("Sent 3 suggestions."),
            Lines.resultLine(text: "Sent 3 suggestions."),
        ]
        let id = try await start()
        let run = try await finishedRun(id)

        #expect(run.phase == .finished)
        #expect(run.sessionID == Lines.sessionID)
        #expect(run.claudeVersion == "2.1.316")
        #expect(run.appLocalizerCalls == 2)
        #expect(run.result?.text == "Sent 3 suggestions.")
        #expect(run.activity.map(\.kind) == [.started, .appLocalizer, .file, .problem, .appLocalizer, .said])
        #expect(run.activity.map(\.text) == [
            "Claude Code 2.1.316 started",
            "get_store_page",
            "Read CHANGELOG.md",
            "Read CHANGELOG.md failed: File does not exist.",
            "suggest_fields",
            "Sent 3 suggestions.",
        ])
        #expect(run.timeline.count == 5)
        #expect(run.endedAt == clock.now)
        #expect(run.resumeCommand == "cd '\(ClaudeCodeTestFixtures.lumenFolder)' && claude --resume \(Lines.sessionID)")
    }

    @Test func refusedStepsFinishWithTheirList() async throws {
        let denials = #"[{"tool_name":"Bash","tool_use_id":"d1","tool_input":{"command":"swift package resolve"}}]"#
        runner.lines = [Lines.initLine(), Lines.resultLine(text: "Couldn’t resolve packages.", denials: denials)]
        let run = try await finishedRun(start())
        #expect(run.phase == .finished)
        #expect(run.denials == [ClaudeCodeResult.Denial(toolName: "Bash", summary: "swift package resolve")])
        #expect(run.statusTitle == "Finished · 1 step wasn’t allowed")
    }

    @Test func stopEndsItAndKeepsWhatItDid() async throws {
        runner.lines = [Lines.initLine(), Lines.toolUseLine("mcp__applocalizer__get_store_page", id: "t1")]
        runner.exitStatus = nil
        let id = try await start()
        await MCPTestFixtures.waitUntil { launcher.run(id)?.appLocalizerCalls == 1 }
        #expect(launcher.activeRuns.map(\.id) == [id])

        launcher.stop(id)
        let run = try await finishedRun(id)
        #expect(run.phase == .stopped)
        #expect(run.appLocalizerCalls == 1)
        #expect(launcher.activeRuns.isEmpty)
    }

    /// Claude Code's result is its last word: a helper that doesn't end
    /// after it is told to stop, and the run ends on its result, once, so
    /// Continue and Retry can start another.
    @Test func aHelperThatDoesntEndAfterTheResultEndsTheRunAnyway() async throws {
        runner.lines = [Lines.initLine(), Lines.resultLine(text: "Sent 182 of 252 captures; iPhone Duo waits for you.")]
        runner.exitStatus = nil
        launcher.resultGrace = .milliseconds(50)
        let endings = EndedRuns()
        launcher.onRunEnded = { endings.phases.append($0.phase) }

        let id = try await start(.autopilot, prompt: "Capture screenshots")
        let run = try await finishedRun(id)
        #expect(run.phase == .finished)
        #expect(run.result?.text == "Sent 182 of 252 captures; iPhone Duo waits for you.")
        #expect(assistants.runTokens.isEmpty)

        // Told to stop, the helper ends after all: the run stays finished.
        await MCPTestFixtures.waitUntil { runner.recordedArguments.count(where: { $0.first == "run" }) == 1 }
        try await Task.sleep(for: .milliseconds(200))
        #expect(launcher.run(id)?.phase == .finished)
        #expect(endings.phases == [.finished])

        let next = try await start(.autopilot, prompt: "Continue the run")
        #expect(next != id)
        await ClaudeCodeTestFixtures.waitForEnd(of: next, in: launcher)
    }

    @Test func askingAgainWhileItRunsReturnsTheSameRun() async throws {
        runner.exitStatus = nil
        let id = try await start()
        await ClaudeCodeTestFixtures.waitForHelper(runner)
        let again = try await start(prompt: "Suggest everything again")
        #expect(again == id)
        #expect(runner.recordedArguments.filter { $0.first == "run" }.count == 1)

        let other = try await start(.autopilot, prompt: "Capture screenshots")
        #expect(other != id)
        #expect(launcher.activeRuns.count == 2)
        launcher.stop(id)
        launcher.stop(other)
        await ClaudeCodeTestFixtures.waitForEnd(of: other, in: launcher)
    }

    @Test func notLoggedInSaysSo() async throws {
        runner.lines = [Lines.initLine(), Lines.resultLine(isError: true, text: "Invalid API key · Please run /login")]
        runner.exitStatus = 1
        let run = try await finishedRun(start())
        #expect(run.failure == .notLoggedIn("Invalid API key · Please run /login"))
        #expect(run.failure?.suggestsTerminal == true)
    }

    @Test func aServerThatDidntConnectIsTheProblem() async throws {
        runner.lines = [Lines.initLine(serverStatus: "failed"), Lines.resultLine(isError: true, text: "I couldn’t reach AppLocalizer.")]
        runner.exitStatus = 1
        let run = try await finishedRun(start())
        #expect(run.failure == .serverNotConnected)
        #expect(run.activity.contains { $0.kind == .problem && $0.text == "AppLocalizer’s server didn’t connect." })
    }

    @Test func aServerThatCantStartFailsTheRunAtOnce() async throws {
        server.failure = "Port 47321 is in use."
        let run = try await finishedRun(start())
        #expect(run.failure == .serverUnavailable("Port 47321 is in use."))
        #expect(runner.lastRunArguments == nil)
    }

    @Test func aMissingFolderAsksForItAgainOnRetry() async throws {
        runner.exitStatus = ClaudeCodeRunFailure.folderMissingStatus
        runner.errorOutput = "The project folder /Users/sam/Developer/Lumen isn't there."
        let failed = try await finishedRun(start())
        #expect(failed.failure == .folderMissing(ClaudeCodeTestFixtures.lumenFolder))

        runner.exitStatus = 0
        runner.lines = [Lines.initLine(), Lines.resultLine(text: "Done.")]
        launcher.folderChooser = { _, _ in "/Users/sam/Moved/Lumen" }
        let retried = try #require(await launcher.retry(failed.id))
        let run = try await finishedRun(retried)
        #expect(run.phase == .finished)
        #expect(run.workingDirectory == "/Users/sam/Moved/Lumen")
        #expect(run.prompt == failed.prompt)
        #expect(launcher.projectFolder(for: ClaudeCodeTestFixtures.lumenID) == "/Users/sam/Moved/Lumen")

        launcher.folderChooser = { _, _ in nil }
        runner.lines = []
        runner.exitStatus = ClaudeCodeRunFailure.folderMissingStatus
        let failedAgain = try await finishedRun(start())
        #expect(await launcher.retry(failedAgain.id) == nil)
    }

    @Test func otherEndsAreClassified() async throws {
        runner.exitStatus = ClaudeCodeRunFailure.claudeMissingStatus
        #expect(try await finishedRun(start()).failure == .claudeMissing)

        runner.exitStatus = 1
        runner.errorOutput = "node: bad option"
        #expect(try await finishedRun(start()).failure == .exited(status: 1, message: "node: bad option"))
    }

    @Test func aRunThatStartedButLostItsEndDidStart() async throws {
        let writeError = "Start Claude Code.zsh:111: write error: resource temporarily unavailable"
        runner.lines = [Lines.initLine(), Lines.saidLine("Capturing the Week screen.")]
        runner.losesExitLine = true
        runner.errorOutput = writeError
        runner.taskError = "The script exited with status 1."
        let run = try await finishedRun(start())
        #expect(run.failure == .exited(status: nil, message: writeError))
        #expect(run.failure?.title == "Claude Code ended early")
        #expect(run.failure?.suggestsTerminal == true)

        // Nothing from Claude Code at all: the helper itself didn't run.
        runner.lines = []
        #expect(try await finishedRun(start()).failure == .couldNotStart("The script exited with status 1."))
    }

    @Test func latestRunFindsTheOneForThisRequest() async throws {
        let first = try await finishedRun(start())
        clock.advance(by: 60)
        let opened = clock.now
        #expect(launcher.latestRun(appID: ClaudeCodeTestFixtures.lumenID, purpose: .suggestEverything)?.id == first.id)
        #expect(launcher.latestRun(appID: ClaudeCodeTestFixtures.lumenID, purpose: .suggestEverything, since: opened) == nil)
        #expect(launcher.latestRun(appID: ClaudeCodeTestFixtures.lumenID, purpose: .autopilot) == nil)
        #expect(launcher.latestRun(appID: ClaudeCodeTestFixtures.tempoID, purpose: .suggestEverything) == nil)

        // Started a moment before the request was noted still counts.
        let second = try await finishedRun(start())
        #expect(launcher.latestRun(appID: ClaudeCodeTestFixtures.lumenID, purpose: .suggestEverything, since: opened.addingTimeInterval(0.5))?.id == second.id)
    }

    @Test func dismissForgetsOnlyEndedRuns() async throws {
        runner.exitStatus = nil
        let id = try await start()
        launcher.dismiss(id)
        #expect(launcher.run(id) != nil)

        launcher.stop(id)
        _ = try await finishedRun(id)
        launcher.shownRunID = id
        launcher.dismiss(id)
        #expect(launcher.run(id) == nil)
        #expect(launcher.shownRunID == nil)
    }

    @Test func onlyTheNewestRunsAreKept() async throws {
        for index in 0..<(ClaudeCodeLauncher.runLimit + 3) {
            _ = try await finishedRun(start(prompt: "Request \(index)"))
        }
        #expect(launcher.runs.count == ClaudeCodeLauncher.runLimit)
        #expect(launcher.runs.first?.prompt == "Request 3")
        #expect(assistants.runTokens.isEmpty)
    }

    @Test func revokingClaudeCodeStopsItsRunsTokens() async throws {
        runner.exitStatus = nil
        let id = try await start()
        await ClaudeCodeTestFixtures.waitForHelper(runner)
        let token = try runToken()
        let client = try #require(assistants.pairedClients.first)

        assistants.revoke(client.id)
        #expect(assistants.authorizedClientID(for: "Bearer \(token)") == nil)

        // The next run pairs Claude Code again.
        launcher.stop(id)
        _ = try await finishedRun(id)
        runner.exitStatus = 0
        _ = try await finishedRun(start())
        #expect(assistants.pairedClients.count == 1)
        #expect(assistants.pairedClients.first?.id != client.id)
    }

    /// The phases runs ended with, in order.
    private final class EndedRuns {
        var phases: [ClaudeCodeRun.Phase] = []
    }
}
