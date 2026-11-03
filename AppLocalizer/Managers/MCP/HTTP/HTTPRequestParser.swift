//
//  HTTPRequestParser.swift
//  AppLocalizer
//

import Foundation

/// Reads HTTP/1.1 requests from the bytes of one connection as they arrive.
/// A connection can carry several requests (keep-alive), so `nextRequest()`
/// takes one complete request off the front and leaves the rest. Bodies come
/// with `Content-Length` or chunked.
struct HTTPRequestParser {
    static let maximumHeaderSize = 16 * 1024
    /// Room for an Autopilot capture: a 13″ iPad PNG can pass 20 MB.
    static let maximumBodySize = 40 * 1024 * 1024
    /// Room for an App Preview's Simulator recording, sent to Autopilot's
    /// upload link only.
    static let maximumUploadBodySize = 512 * 1024 * 1024

    /// The largest body a request to `target` may carry.
    static func maximumBodySize(for target: String) -> Int {
        target.hasPrefix(MCPEndpoint.autopilotPath) ? maximumUploadBodySize : maximumBodySize
    }

    private(set) var buffer = Data()

    mutating func append(_ data: Data) {
        buffer.append(data)
    }

    /// The next complete request, removed from the buffer; nil while more
    /// bytes are needed.
    mutating func nextRequest() throws(HTTPParseError) -> HTTPRequest? {
        guard let headerEnd = buffer.range(of: Self.headerTerminator) else {
            if buffer.count > Self.maximumHeaderSize { throw .headersTooLarge }
            return nil
        }
        let headerLength = headerEnd.lowerBound - buffer.startIndex
        guard headerLength <= Self.maximumHeaderSize else { throw .headersTooLarge }
        guard let headText = String(bytes: buffer[buffer.startIndex..<headerEnd.lowerBound], encoding: .utf8) else { throw .malformed }
        let head = try Self.head(headText)
        let bodyStart = headerEnd.upperBound
        let limit = Self.maximumBodySize(for: head.target)

        let body: Data
        let requestEnd: Data.Index
        if let encoding = head.headers["transfer-encoding"]?.lowercased() {
            guard encoding == "chunked" else { throw .unsupportedTransferEncoding }
            guard let (decoded, end) = try Self.chunkedBody(in: buffer, from: bodyStart, limit: limit) else { return nil }
            body = decoded
            requestEnd = end
        } else {
            let length = try Self.contentLength(head.headers["content-length"], limit: limit)
            guard buffer.endIndex - bodyStart >= length else { return nil }
            body = Data(buffer[bodyStart..<bodyStart + length])
            requestEnd = bodyStart + length
        }

        buffer = Data(buffer[requestEnd...])
        return HTTPRequest(method: head.method, target: head.target, version: head.version, headers: head.headers, body: body)
    }

    private static let headerTerminator = Data("\r\n\r\n".utf8)
    private static let lineTerminator = Data("\r\n".utf8)

    private struct Head {
        var method: String
        var target: String
        var version: String
        var headers: [String: String]
    }

    private static func head(_ text: String) throws(HTTPParseError) -> Head {
        var lines = text.components(separatedBy: "\r\n")
        let requestLine = lines.removeFirst().split(separator: " ", omittingEmptySubsequences: true)
        guard requestLine.count == 3, requestLine[2].hasPrefix("HTTP/1.") else { throw .malformed }
        var headers: [String: String] = [:]
        for line in lines where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { throw .malformed }
            let name = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { throw .malformed }
            headers[name] = headers[name].map { "\($0), \(value)" } ?? value
        }
        return Head(method: String(requestLine[0]), target: String(requestLine[1]), version: String(requestLine[2]), headers: headers)
    }

    private static func contentLength(_ value: String?, limit: Int) throws(HTTPParseError) -> Int {
        guard let value else { return 0 }
        guard let length = Int(value), length >= 0 else { throw .malformed }
        guard length <= limit else { throw .bodyTooLarge }
        return length
    }

    /// The decoded body and where the request ends, or nil while the last
    /// chunk hasn't arrived. Chunk extensions and trailers are ignored.
    private static func chunkedBody(in buffer: Data, from start: Data.Index, limit: Int) throws(HTTPParseError) -> (Data, Data.Index)? {
        var body = Data()
        var cursor = start
        while true {
            guard let lineEnd = buffer[cursor...].range(of: lineTerminator) else { return nil }
            let sizeText = (String(bytes: buffer[cursor..<lineEnd.lowerBound], encoding: .ascii) ?? "")
                .split(separator: ";").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
            guard let size = Int(sizeText, radix: 16), size >= 0 else { throw .malformed }
            cursor = lineEnd.upperBound
            if size == 0 {
                // Trailers, if any, end with an empty line.
                guard let end = buffer[cursor...].range(of: lineTerminator) else { return nil }
                if end.lowerBound == cursor { return (body, end.upperBound) }
                guard let trailersEnd = buffer[cursor...].range(of: headerTerminator) else { return nil }
                return (body, trailersEnd.upperBound)
            }
            guard body.count + size <= limit else { throw .bodyTooLarge }
            guard buffer.endIndex - cursor >= size + 2 else { return nil }
            body.append(buffer[cursor..<cursor + size])
            cursor += size
            guard buffer[cursor..<cursor + 2] == lineTerminator else { throw .malformed }
            cursor += 2
        }
    }
}
