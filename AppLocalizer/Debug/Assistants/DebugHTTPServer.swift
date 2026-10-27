//
//  DebugHTTPServer.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// A server for DEBUG scenes that never opens a port: starting reports it
/// listening at once, so Settings → AI Assistants shows the running state
/// without anything on this Mac being able to connect.
final class DebugHTTPServer: LocalHTTPServing {
    func start(port: UInt16, handler _: @escaping Handler, onEvent: @escaping EventHandler) {
        onEvent(.ready(port: port))
    }

    func stop() {}
}
#endif
