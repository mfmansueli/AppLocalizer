//
//  JSONRPCMessageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("JSON-RPC messages")
struct JSONRPCMessageTests {
    private func message(_ text: String) throws -> JSONRPCMessage {
        try JSONDecoder().decode(JSONRPCMessage.self, from: Data(text.utf8))
    }

    @Test func tellsRequestsNotificationsAndResponsesApart() throws {
        #expect(try message(#"{"jsonrpc":"2.0","id":1,"method":"ping"}"#).kind == .request)
        #expect(try message(#"{"jsonrpc":"2.0","id":"a","method":"tools/list","params":{}}"#).kind == .request)
        #expect(try message(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#).kind == .notification)
        #expect(try message(#"{"jsonrpc":"2.0","id":"roots-1","result":{"roots":[]}}"#).kind == .response)
        #expect(try message(#"{"jsonrpc":"2.0","id":2,"error":{"code":-1,"message":"No"}}"#).kind == .response)
    }

    @Test func refusesWhatIsntJSONRPC2() throws {
        #expect(try message(#"{"jsonrpc":"1.0","id":1,"method":"ping"}"#).kind == nil)
        #expect(try message(#"{"jsonrpc":"2.0","id":1}"#).kind == nil)
        #expect(throws: (any Error).self) { try message(#"{"id":1,"method":"ping"}"#) }
    }

    @Test func responsesEncodeTheirResultOrError() throws {
        let result = try JSONValue(encoding: JSONRPCResponse.result(["ok": true], id: 7))
        #expect(result == ["jsonrpc": "2.0", "id": 7, "result": ["ok": true]])
        let error = try JSONValue(encoding: JSONRPCResponse.error(.methodNotFound("nope"), id: "x"))
        #expect(error == ["jsonrpc": "2.0", "id": "x", "error": ["code": -32601, "message": "Method not found: nope"]])
        let unread = try JSONValue(encoding: JSONRPCResponse.error(.parseError))
        #expect(unread["id"] == .null)
        #expect(unread["error"]?["code"] == -32700)
    }

    @Test func errorsUseTheStandardCodes() {
        #expect(JSONRPCError.invalidRequest("x").code == -32600)
        #expect(JSONRPCError.invalidParams("x").code == -32602)
        #expect(JSONRPCError.internalError("x").code == -32603)
    }
}
