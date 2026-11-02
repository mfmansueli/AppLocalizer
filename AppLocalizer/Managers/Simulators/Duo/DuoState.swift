//
//  DuoState.swift
//  AppLocalizer
//

import Foundation

/// iPhone Duo's simulator as AppLocalizer last saw it (`DuoWatcher`).
enum DuoState: Hashable, Sendable {
    /// Not looked at yet.
    case unknown
    /// No helper to ask.
    case noHelper
    /// A helper from before it could look at the Duo: it needs saving again.
    case oldHelper
    /// No iPhone Duo simulator on this Mac.
    case noSimulator
    case notRunning
    /// AppLocalizer is starting it.
    case starting
    /// Its inner display is black: the person opens it in Device Hub.
    case closed
    /// Its inner display shows only a spinner, for now.
    case spinner
    /// It's stuck, and AppLocalizer is restarting it.
    case restarting(DuoStep.Reason)
    /// Still stuck after restarting it: the person erases it.
    case stuck(DuoStep.Reason)
    /// Its inner display shows the Home Screen or an app.
    case open
    /// The helper couldn't read it: why.
    case failed(String)

    init(_ inner: DuoInnerDisplay) {
        switch inner {
        case .black: self = .closed
        case .spinner: self = .spinner
        case .showing: self = .open
        }
    }

    /// AppLocalizer is starting or restarting it.
    var isWorking: Bool {
        switch self {
        case .starting, .restarting: true
        default: false
        }
    }

    /// AppLocalizer can see it, so a stuck one is restarted and an opened
    /// one goes on by itself.
    var isWatched: Bool {
        switch self {
        case .unknown, .noHelper, .oldHelper, .noSimulator, .failed: false
        default: true
        }
    }

    /// "Closed: open it in Device Hub."
    var summary: String {
        switch self {
        case .unknown:
            String(localized: "Looking at iPhone Duo…")
        case .noHelper:
            String(localized: "Install the helper so AppLocalizer can see whether iPhone Duo is open.")
        case .oldHelper:
            String(localized: "Save the helper again so AppLocalizer can see whether iPhone Duo is open, and restart it when it’s stuck.")
        case .noSimulator:
            String(localized: "There’s no iPhone Duo simulator on this Mac yet.")
        case .notRunning:
            String(localized: "Not running: start it in Device Hub, then open it.")
        case .starting:
            String(localized: "Starting iPhone Duo…")
        case .closed:
            String(localized: "Closed: open it in Device Hub.")
        case .spinner:
            String(localized: "Its inner display shows a spinner while it starts.")
        case .restarting(.springBoardCrashed):
            String(localized: "Stuck, its SpringBoard crashed: AppLocalizer is restarting it…")
        case .restarting(.spinner):
            String(localized: "Stuck on a spinner: AppLocalizer is restarting it…")
        case .stuck:
            String(localized: "Still stuck after restarting it twice: erase it in Device Hub, start it, then open it.")
        case .open:
            String(localized: "Open.")
        case let .failed(reason):
            reason
        }
    }
}
