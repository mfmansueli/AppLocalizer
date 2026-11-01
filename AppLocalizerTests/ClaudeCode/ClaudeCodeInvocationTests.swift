//
//  ClaudeCodeInvocationTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The arguments a run passes to `claude`: a restricted print run that
/// streams JSON and knows only AppLocalizer's server, with its own token.
@Suite("Claude Code invocation")
struct ClaudeCodeInvocationTests {
    private func invocation(_ permissions: ClaudeCodePermissions = .readProject) -> ClaudeCodeInvocation {
        ClaudeCodeInvocation(
            workingDirectory: "/Users/sam/Developer/Lumen",
            prompt: "Suggest What’s New for Lumen Journal 1.4",
            permissions: permissions,
            port: 47399,
            token: "al_pair_run",
            sessionName: "AppLocalizer · Suggest Everything · Lumen Journal"
        )
    }

    private func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private func json(_ text: String?) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(#require(text).utf8))
    }

    @Test func theHelperRunsClaudeInTheProjectFolder() {
        let arguments = invocation().helperArguments
        #expect(Array(arguments.prefix(3)) == ["run", "/Users/sam/Developer/Lumen", "--"])
        #expect(Array(arguments.dropFirst(3)) == invocation().claudeArguments)
    }

    @Test func itsARestrictedPrintRunThatStreamsJSON() {
        let arguments = invocation().claudeArguments
        #expect(value(after: "-p", in: arguments) == "Suggest What’s New for Lumen Journal 1.4")
        #expect(value(after: "--output-format", in: arguments) == "stream-json")
        #expect(value(after: "--permission-mode", in: arguments) == "dontAsk")
        #expect(value(after: "--name", in: arguments) == "AppLocalizer · Suggest Everything · Lumen Journal")
        #expect(value(after: "--append-system-prompt", in: arguments) == ClaudeCodePermissions.readProject.systemPrompt)
        for flag in ["--verbose", "--restricted", "--strict-mcp-config"] {
            #expect(arguments.contains(flag), "\(flag)")
        }
        #expect(!arguments.contains("--dangerously-skip-permissions"))
    }

    @Test func toolsComeLastBecauseTheyreVariadic() throws {
        let arguments = invocation().claudeArguments
        let index = try #require(arguments.firstIndex(of: "--tools"))
        #expect(Array(arguments[(index + 1)...]) == ["Read", "Grep", "Glob", "Bash"])

        let testArguments = invocation(.appLocalizerOnly).claudeArguments
        #expect(Array(testArguments.suffix(2)) == ["--tools", ""])
    }

    @Test func onlyAppLocalizersServerWithTheRunsToken() throws {
        let configuration = try json(value(after: "--mcp-config", in: invocation().claudeArguments))
        let servers = try #require(configuration["mcpServers"]?.objectValue)
        #expect(Array(servers.keys) == [MCPEndpoint.serverName])
        let server = try #require(servers[MCPEndpoint.serverName])
        #expect(server["type"]?.stringValue == "http")
        #expect(server["url"]?.stringValue == "http://127.0.0.1:47399/mcp")
        #expect(server["headers"]?["Authorization"]?.stringValue == "Bearer al_pair_run")
    }

    @Test func settingsAllowOnlyThePermissionsRules() throws {
        let settings = try json(value(after: "--settings", in: invocation(.autopilot).claudeArguments))
        let allow = try #require(settings["permissions"]?["allow"]?.arrayValue).compactMap(\.stringValue)
        #expect(allow == ClaudeCodePermissions.autopilot.allowRules(port: 47399))
        #expect(settings.objectValue?.keys.sorted() == ["permissions"])
    }
}
