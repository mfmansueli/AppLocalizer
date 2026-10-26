//
//  MCPBridgeEventStreamTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing

@Suite("MCPBridgeEventStream")
struct MCPBridgeEventStreamTests {
    @Test func eachEventIsOneMessage() {
        let body = "id: 1\r\ndata: {\"a\":1}\r\n\r\n: keep-alive\n\nevent: message\ndata:{\"b\":2}\n\n"
        #expect(MCPBridgeEventStream.messages(in: Data(body.utf8)) == [#"{"a":1}"#, #"{"b":2}"#])
    }

    @Test func dataLinesOfOneEventAreJoined() {
        #expect(MCPBridgeEventStream.messages(in: Data("data: {\"a\":\ndata: 1}\n\n".utf8)) == ["{\"a\":\n1}"])
    }
}
