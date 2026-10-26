//
//  LocalHTTPServerEvent.swift
//  AppLocalizer
//

import Foundation

/// What happened to the listening socket.
enum LocalHTTPServerEvent: Equatable, Sendable {
    /// Listening on `port`.
    case ready(port: UInt16)
    /// Couldn't listen, e.g. another app already uses the port.
    case failed(message: String)
}
