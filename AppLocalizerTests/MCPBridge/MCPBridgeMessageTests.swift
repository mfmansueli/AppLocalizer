//
//  MCPBridgeMessageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing

@Suite("MCPBridgeMessage")
struct MCPBridgeMessageTests {
    @Test func requestsKeepTheirIDAsJSON() throws {
        let numbered = try #require(MCPBridgeMessage(line: #"{"jsonrpc":"2.0","id":7,"method":"tools/call"}"#))
        #expect(numbered.idJSON == "7")
        #expect(numbered.isRequest)
        let named = try #require(MCPBridgeMessage(line: #"{"jsonrpc":"2.0","id":"x\"1","method":"initialize"}"#))
        #expect(named.idJSON == #""x\"1""#)
        #expect(named.isInitialize)
    }

    @Test func notificationsAndResponsesArentRequests() throws {
        #expect(try #require(MCPBridgeMessage(line: #"{"jsonrpc":"2.0","method":"notifications/initialized"}"#)).isRequest == false)
        #expect(try #require(MCPBridgeMessage(line: #"{"jsonrpc":"2.0","id":3,"result":{}}"#)).isRequest == false)
        #expect(MCPBridgeMessage(line: "[1,2]") == nil)
    }

    @Test func errorsEscapeTheirMessage() throws {
        let line = MCPBridgeMessage.error(id: "7", code: -32000, message: "Can’t say \"hi\"\n")
        let object = try #require(try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
        #expect(object["id"] as? Int == 7)
        #expect((object["error"] as? [String: Any])?["message"] as? String == "Can’t say \"hi\"\n")
        #expect(!line.contains("\n"))
    }
}
