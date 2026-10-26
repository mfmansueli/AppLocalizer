//
//  HTTPReply.swift
//  AppLocalizer
//

import Foundation

/// What the MCP endpoint answers a request with.
enum HTTPReply: Sendable {
    case response(HTTPResponse)
    /// Keeps the connection open as a server-sent events stream.
    case events(HTTPEventStream)
}
