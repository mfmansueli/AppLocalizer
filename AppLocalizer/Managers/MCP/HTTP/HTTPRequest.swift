//
//  HTTPRequest.swift
//  AppLocalizer
//

import Foundation

/// One HTTP/1.1 request read from an MCP client's connection.
struct HTTPRequest: Hashable, Sendable {
    var method: String
    /// The request target as sent, e.g. `/mcp` or `/mcp?x=1`.
    var target: String
    /// e.g. `HTTP/1.1`.
    var version: String
    /// Header names are lowercased; repeated headers are joined with ", ".
    var headers: [String: String]
    var body: Data

    init(method: String, target: String, version: String = "HTTP/1.1", headers: [String: String] = [:], body: Data = Data()) {
        self.method = method.uppercased()
        self.target = target
        self.version = version
        self.headers = Dictionary(headers.map { ($0.key.lowercased(), $0.value) }) { first, second in "\(first), \(second)" }
        self.body = body
    }

    /// The target without its query.
    var path: String {
        String(target.prefix { $0 != "?" })
    }

    func header(_ name: String) -> String? {
        headers[name.lowercased()]
    }

    /// HTTP/1.1 keeps the connection open unless the client says
    /// `Connection: close`; HTTP/1.0 only with `Connection: keep-alive`.
    var keepsAlive: Bool {
        let connection = header("connection")?.lowercased() ?? ""
        if version == "HTTP/1.0" { return connection.contains("keep-alive") }
        return !connection.contains("close")
    }
}
