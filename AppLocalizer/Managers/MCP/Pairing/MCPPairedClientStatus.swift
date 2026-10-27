//
//  MCPPairedClientStatus.swift
//  AppLocalizer
//

import Foundation

/// How a paired assistant is doing, as its row in Settings says it.
enum MCPPairedClientStatus: Hashable, Sendable {
    /// It has a session open; `lastCall` is its latest request.
    case connected(lastCall: Date)
    /// It connected while AppLocalizer was open, then went away.
    case disconnected(lastSeen: Date)
    /// It hasn't connected since AppLocalizer opened; `since` is when it was
    /// last seen, or when it was paired if it never connected.
    case idle(since: Date, everConnected: Bool)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    /// "Connected · last call 10:43", "Disconnected · last seen 10:44",
    /// "Paired · not connected since Oct 22".
    var text: String {
        switch self {
        case let .connected(lastCall):
            String(localized: "Connected · last call \(lastCall.formatted(date: .omitted, time: .shortened))")
        case let .disconnected(lastSeen):
            String(localized: "Disconnected · last seen \(lastSeen.formatted(date: .omitted, time: .shortened))")
        case let .idle(since, everConnected):
            if everConnected {
                String(localized: "Paired · not connected since \(since.formatted(.dateTime.month(.abbreviated).day()))")
            } else {
                String(localized: "Paired · not connected yet")
            }
        }
    }
}
