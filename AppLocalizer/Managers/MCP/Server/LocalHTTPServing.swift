//
//  LocalHTTPServing.swift
//  AppLocalizer
//

import Foundation

/// Accepts HTTP connections on this Mac's loopback address and hands every
/// request to a handler. `LocalHTTPServer` is the real one; DEBUG scenes and
/// tests use one that never opens a port.
protocol LocalHTTPServing: AnyObject, Sendable {
    typealias Handler = @Sendable (HTTPRequest) async -> HTTPReply
    typealias EventHandler = @Sendable (LocalHTTPServerEvent) -> Void

    /// Starts listening on 127.0.0.1:`port` (0 picks a free port). Replaces
    /// a server that's already running.
    func start(port: UInt16, handler: @escaping Handler, onEvent: @escaping EventHandler)
    /// Stops listening and closes every connection.
    func stop()
}
