//
//  FakeBridgeTransport.swift
//  AppLocalizerTests
//

import Foundation

/// Answers the bridge's requests from a script, oldest first, and keeps them.
actor FakeBridgeTransport: MCPBridgeTransport {
    /// One scripted reply.
    struct Reply {
        var status = 200
        var headers = ["Content-Type": "application/json"]
        var body = ""
    }

    private var replies: [Result<Reply, URLError>]
    private(set) var requests: [URLRequest] = []

    init(_ replies: [Result<Reply, URLError>]) {
        self.replies = replies
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        guard !replies.isEmpty else { throw URLError(.cannotConnectToHost) }
        let reply = try replies.removeFirst().get()
        let response = HTTPURLResponse(url: request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
        return (Data(reply.body.utf8), response)
    }

    /// The bodies the bridge posted, as text.
    var bodies: [String] {
        requests.map { String(bytes: $0.httpBody ?? Data(), encoding: .utf8) ?? "" }
    }
}
