//
//  HTTPEventStream.swift
//  AppLocalizer
//

import Foundation

/// A server-sent events stream an MCP client opened with `GET`: the
/// connection writes each chunk of `events` as it arrives and stays open
/// until the stream finishes or the client goes away, then calls `onClose`.
struct HTTPEventStream: Sendable {
    var headers: [String: String]
    var events: AsyncStream<String>
    var onClose: @Sendable () -> Void

    /// One SSE message carrying a JSON-RPC message.
    static func message(_ json: String) -> String {
        "event: message\ndata: \(json)\n\n"
    }

    /// An SSE comment, sent now and then so idle connections stay open.
    static let keepAlive = ": keep-alive\n\n"
}
