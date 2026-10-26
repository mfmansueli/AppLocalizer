//
//  MCPBridgeOptionsTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing

@Suite("MCPBridgeOptions")
struct MCPBridgeOptionsTests {
    @Test func theTokenIsRequiredAndTheURLDefaultsToThisMac() throws {
        let options = try MCPBridgeOptions(arguments: ["--token", "al_tok"])
        #expect(try options == MCPBridgeOptions(token: "al_tok", url: #require(URL(string: "http://127.0.0.1:47321/mcp"))))
        #expect(throws: MCPBridgeOptions.Problem.missingToken) { try MCPBridgeOptions(arguments: []) }
    }

    @Test func aLoopbackURLCanBeGiven() throws {
        let options = try MCPBridgeOptions(arguments: ["--url", "http://localhost:50000/mcp", "--token", "al_tok"])
        #expect(options.url.absoluteString == "http://localhost:50000/mcp")
    }

    @Test(arguments: ["https://example.com/mcp", "http://192.168.1.4:47321/mcp", "ftp://127.0.0.1/mcp"])
    func theTokenNeverLeavesThisMac(url: String) {
        #expect(throws: MCPBridgeOptions.Problem.notLoopback(url)) { try MCPBridgeOptions(arguments: ["--token", "t", "--url", url]) }
    }

    @Test func badArgumentsAreExplained() {
        #expect(throws: MCPBridgeOptions.Problem.missingValue("--token")) { try MCPBridgeOptions(arguments: ["--token"]) }
        #expect(throws: MCPBridgeOptions.Problem.missingValue("--token")) { try MCPBridgeOptions(arguments: ["--token", "--url"]) }
        #expect(throws: MCPBridgeOptions.Problem.unknownArgument("--pair")) { try MCPBridgeOptions(arguments: ["--pair"]) }
        #expect(throws: MCPBridgeOptions.Problem.help) { try MCPBridgeOptions(arguments: ["--token", "t", "-h"]) }
        #expect(MCPBridgeOptions.Problem.missingToken.message.contains("Settings → AI Assistants"))
    }
}
