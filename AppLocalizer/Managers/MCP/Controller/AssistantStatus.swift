//
//  AssistantStatus.swift
//  AppLocalizer
//

import Foundation

/// How far the person's own assistant is set up, as the toolbar's Assistant
/// button, the overview and the suggestion bars say it: an assistant over
/// MCP, or an API key. The status dot is never alone: every place says the
/// state in words too.
enum AssistantStatus: Hashable, Sendable {
    /// The local server is off, or no assistant has a token yet.
    case notSetUp
    /// The server is on and an assistant has its token, but it hasn't
    /// called AppLocalizer yet.
    case waiting(client: String)
    /// An assistant has called AppLocalizer.
    case connected(client: String)
    /// No assistant is connected, but an API key is set up: AppLocalizer
    /// asks the model itself, e.g. "Anthropic API".
    case ready(client: String)

    /// e.g. "Claude Code"; nil before setup.
    var clientName: String? {
        switch self {
        case .notSetUp: nil
        case let .waiting(client), let .connected(client), let .ready(client): client
        }
    }

    /// An API key, not an assistant: Generate Suggestions… instead of Ask.
    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }

    /// Something can be asked for suggestions now.
    var canSuggest: Bool { isConnected || isReady }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var isWaiting: Bool {
        if case .waiting = self { return true }
        return false
    }

    /// "Not set up", "Waiting for a first call", "Connected", "Ready".
    var title: String {
        switch self {
        case .notSetUp: String(localized: "Not set up")
        case .waiting: String(localized: "Waiting for a first call")
        case .connected: String(localized: "Connected")
        case .ready: String(localized: "Ready")
        }
    }

    /// "Set Up Assistant…", or "Finish Setup…" once a token is out.
    var setupTitle: String {
        isWaiting ? String(localized: "Finish Setup…") : String(localized: "Set Up Assistant…")
    }

    /// The suggestion bar's button: "Ask Claude Code…" once connected,
    /// "Generate Suggestions…" with a key, else the setup button.
    var askTitle: String {
        switch self {
        case let .connected(client): String(localized: "Ask \(client)…")
        case .ready: String(localized: "Generate Suggestions…")
        case .notSetUp, .waiting: setupTitle
        }
    }
}
