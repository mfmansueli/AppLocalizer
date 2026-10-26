//
//  HTTPRequestParserTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("HTTPRequestParser")
struct HTTPRequestParserTests {
    private func parser(_ text: String) -> HTTPRequestParser {
        var parser = HTTPRequestParser()
        parser.append(Data(text.utf8))
        return parser
    }

    @Test func readsARequestWithItsHeadersAndBody() throws {
        var parser = parser("post /mcp?x=1 HTTP/1.1\r\nHost: 127.0.0.1:47321\r\nContent-Type: application/json\r\nContent-Length: 2\r\n\r\n{}")
        let request = try #require(try parser.nextRequest())
        #expect(request.method == "POST")
        #expect(request.target == "/mcp?x=1")
        #expect(request.path == "/mcp")
        #expect(request.version == "HTTP/1.1")
        #expect(request.headers["content-type"] == "application/json")
        #expect(request.header("HOST") == "127.0.0.1:47321")
        #expect(request.body == Data("{}".utf8))
        #expect(parser.buffer.isEmpty)
    }

    @Test func waitsForTheRestOfTheHeadersAndTheBody() throws {
        var parser = parser("POST /mcp HTTP/1.1\r\nContent-Length: 5\r\n")
        #expect(try parser.nextRequest() == nil)
        parser.append(Data("\r\nhel".utf8))
        #expect(try parser.nextRequest() == nil)
        parser.append(Data("lo".utf8))
        #expect(try parser.nextRequest()?.body == Data("hello".utf8))
    }

    @Test func splitsRequestsSentBackToBack() throws {
        var parser = parser("GET /a HTTP/1.1\r\n\r\nDELETE /b HTTP/1.1\r\nContent-Length: 0\r\n\r\nGET /c")
        #expect(try parser.nextRequest()?.target == "/a")
        #expect(try parser.nextRequest()?.method == "DELETE")
        #expect(try parser.nextRequest() == nil)
        #expect(parser.buffer == Data("GET /c".utf8))
    }

    @Test func joinsRepeatedHeaders() throws {
        var parser = parser("GET / HTTP/1.1\r\nAccept: application/json\r\naccept: text/event-stream\r\n\r\n")
        #expect(try parser.nextRequest()?.header("accept") == "application/json, text/event-stream")
    }

    @Test func decodesChunkedBodiesIgnoringExtensions() throws {
        var parser = parser("POST /mcp HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n4;ext=1\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\nGET /next HTTP/1.1\r\n\r\n")
        #expect(try parser.nextRequest()?.body == Data("Wikipedia".utf8))
        #expect(try parser.nextRequest()?.target == "/next")
    }

    @Test func waitsForTheLastChunkAndSkipsTrailers() throws {
        var parser = parser("POST /mcp HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n4\r\nWiki\r\n")
        #expect(try parser.nextRequest() == nil)
        parser.append(Data("0\r\nX-Trailer: yes\r\n\r\n".utf8))
        #expect(try parser.nextRequest()?.body == Data("Wiki".utf8))
        #expect(parser.buffer.isEmpty)
    }

    @Test func refusesMalformedRequests() {
        var missingVersion = parser("GET /\r\n\r\n")
        #expect(throws: HTTPParseError.malformed) { try missingVersion.nextRequest() }
        var headerWithoutColon = parser("GET / HTTP/1.1\r\nNonsense\r\n\r\n")
        #expect(throws: HTTPParseError.malformed) { try headerWithoutColon.nextRequest() }
        var badLength = parser("POST / HTTP/1.1\r\nContent-Length: two\r\n\r\n")
        #expect(throws: HTTPParseError.malformed) { try badLength.nextRequest() }
        var badChunk = parser("POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\n")
        #expect(throws: HTTPParseError.malformed) { try badChunk.nextRequest() }
    }

    @Test func refusesOversizedRequests() {
        var endlessHeaders = parser("GET / HTTP/1.1\r\nX-Long: \(String(repeating: "a", count: HTTPRequestParser.maximumHeaderSize))")
        #expect(throws: HTTPParseError.headersTooLarge) { try endlessHeaders.nextRequest() }
        var hugeBody = parser("POST / HTTP/1.1\r\nContent-Length: \(HTTPRequestParser.maximumBodySize + 1)\r\n\r\n")
        #expect(throws: HTTPParseError.bodyTooLarge) { try hugeBody.nextRequest() }
    }

    @Test func refusesTransferEncodingsOtherThanChunked() {
        var parser = parser("POST / HTTP/1.1\r\nTransfer-Encoding: gzip\r\n\r\n")
        #expect(throws: HTTPParseError.unsupportedTransferEncoding) { try parser.nextRequest() }
    }

    @Test func eachErrorAnswersWithItsStatus() {
        #expect(HTTPParseError.malformed.statusCode == 400)
        #expect(HTTPParseError.headersTooLarge.statusCode == 431)
        #expect(HTTPParseError.bodyTooLarge.statusCode == 413)
        #expect(HTTPParseError.unsupportedTransferEncoding.statusCode == 501)
    }
}
