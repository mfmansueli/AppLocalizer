//
//  HTTPResponse.swift
//  AppLocalizer
//

import Foundation

/// A complete HTTP response for an MCP client: a JSON-RPC answer, `202
/// Accepted` for a notification, or an error status.
struct HTTPResponse: Hashable, Sendable {
    var status: Int
    var headers: [String: String]
    var body: Data

    init(status: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    /// `value` as `application/json`.
    static func json(_ value: some Encodable, status: Int = 200, headers: [String: String] = [:]) -> HTTPResponse {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let body = (try? encoder.encode(value)) ?? Data("null".utf8)
        return HTTPResponse(status: status, headers: headers.merging(["Content-Type": "application/json"]) { $1 }, body: body)
    }

    /// A status with a short plain-text explanation.
    static func text(_ status: Int, _ message: String? = nil, headers: [String: String] = [:]) -> HTTPResponse {
        let message = message ?? reason(for: status)
        return HTTPResponse(
            status: status,
            headers: headers.merging(["Content-Type": "text/plain; charset=utf-8"]) { $1 },
            body: Data(message.utf8)
        )
    }

    /// The bytes on the wire, with `Content-Length` and `Connection` set.
    func serialized(keepAlive: Bool) -> Data {
        var headers = headers
        headers["Content-Length"] = String(body.count)
        headers["Connection"] = keepAlive ? "keep-alive" : "close"
        var data = Self.head(status: status, headers: headers)
        data.append(body)
        return data
    }

    /// The status line and headers of a response whose body follows later,
    /// e.g. a server-sent events stream.
    static func head(status: Int, headers: [String: String]) -> Data {
        var text = "HTTP/1.1 \(status) \(reason(for: status))\r\n"
        for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
            text += "\(name): \(value)\r\n"
        }
        text += "\r\n"
        return Data(text.utf8)
    }

    static func reason(for status: Int) -> String {
        reasonPhrases[status] ?? "Status \(status)"
    }

    private static let reasonPhrases: [Int: String] = [
        200: "OK",
        202: "Accepted",
        204: "No Content",
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        406: "Not Acceptable",
        413: "Content Too Large",
        415: "Unsupported Media Type",
        431: "Request Header Fields Too Large",
        500: "Internal Server Error",
        501: "Not Implemented",
    ]
}
