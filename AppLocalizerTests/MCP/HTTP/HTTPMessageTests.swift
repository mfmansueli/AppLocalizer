//
//  HTTPMessageTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("HTTP requests and responses")
struct HTTPMessageTests {
    @Test func requestsKeepTheConnectionOpenTheWayEachVersionDoes() {
        #expect(HTTPRequest(method: "GET", target: "/").keepsAlive)
        #expect(!HTTPRequest(method: "GET", target: "/", headers: ["Connection": "close"]).keepsAlive)
        #expect(!HTTPRequest(method: "GET", target: "/", version: "HTTP/1.0").keepsAlive)
        #expect(HTTPRequest(method: "GET", target: "/", version: "HTTP/1.0", headers: ["Connection": "Keep-Alive"]).keepsAlive)
    }

    @Test func responsesSerializeWithTheirLengthAndConnection() {
        let data = HTTPResponse.text(404).serialized(keepAlive: false)
        let expected = "HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 9\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nNot Found"
        #expect(String(bytes: data, encoding: .utf8) == expected)
        let kept = String(bytes: HTTPResponse(status: 202).serialized(keepAlive: true), encoding: .utf8)
        #expect(kept == "HTTP/1.1 202 Accepted\r\nConnection: keep-alive\r\nContent-Length: 0\r\n\r\n")
    }

    @Test func jsonResponsesKeepSlashesAndSetTheContentType() {
        let response = HTTPResponse.json(["url": "http://127.0.0.1:47321/mcp"] as JSONValue, status: 201, headers: ["Mcp-Session-Id": "abc"])
        #expect(response.status == 201)
        #expect(response.headers == ["Content-Type": "application/json", "Mcp-Session-Id": "abc"])
        #expect(String(bytes: response.body, encoding: .utf8) == #"{"url":"http://127.0.0.1:47321/mcp"}"#)
    }

    @Test func textResponsesSayWhy() {
        let response = HTTPResponse.text(401, "Wrong or missing access token.", headers: ["WWW-Authenticate": "Bearer"])
        #expect(response.headers["WWW-Authenticate"] == "Bearer")
        #expect(String(bytes: response.body, encoding: .utf8) == "Wrong or missing access token.")
        #expect(HTTPResponse.reason(for: 431) == "Request Header Fields Too Large")
        #expect(HTTPResponse.reason(for: 299) == "Status 299")
    }

    @Test func eventStreamsFrameMessagesAndKeepAlives() {
        #expect(HTTPEventStream.message(#"{"id":1}"#) == "event: message\ndata: {\"id\":1}\n\n")
        #expect(HTTPEventStream.keepAlive.hasPrefix(":"))
        let head = String(bytes: HTTPResponse.head(status: 200, headers: ["Content-Type": "text/event-stream"]), encoding: .utf8)
        #expect(head == "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n\r\n")
    }
}
