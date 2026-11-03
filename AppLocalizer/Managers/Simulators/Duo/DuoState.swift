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
    /// Its inner display is black: AppLocalizer opens it during a run.
    case closed
    /// Closed for its closed screenshots, on the cover display.
    case closedForScreens
    /// Open while its closed screenshots are next: AppLocalizer is
    /// restarting it, which closes it.
    case closing
    /// AppLocalizer is opening it in Device Hub.
    case opening
    /// Closed, and AppLocalizer needs Accessibility to open it.
    case needsAccessibility
    /// Closed, and the helper is from before it could open it.
    case helperCantOpen
    /// Closed, and AppLocalizer couldn't open it: why.
    case couldntOpen(String)
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

    /// AppLocalizer is starting, opening or restarting it.
    var isWorking: Bool {
        switch self {
        case .starting, .opening, .closing, .restarting: true
        default: false
        }
    }

    /// Closed, and AppLocalizer won't open it by itself: the person opens it
    /// in Device Hub, or does what lets AppLocalizer.
    var waitsForPerson: Bool {
        switch self {
        case .needsAccessibility, .helperCantOpen, .couldntOpen, .stuck: true
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

    /// "Closed: AppLocalizer opens it in Device Hub."
    var summary: String {
        switch self {
        case .unknown:
            String(localized: "Looking at iPhone Duo…")
        case .noHelper:
            String(localized: "Install the helper so AppLocalizer can open iPhone Duo and see whether it’s open.")
        case .oldHelper:
            String(localized: "Save the helper again so AppLocalizer can open iPhone Duo, see whether it’s open, and restart it when it’s stuck.")
        case .noSimulator:
            String(localized: "There’s no iPhone Duo simulator on this Mac yet.")
        case .notRunning:
            String(localized: "Not running: AppLocalizer starts and opens it when the run needs it.")
        case .starting:
            String(localized: "Starting iPhone Duo…")
        case .closed:
            String(localized: "Closed: AppLocalizer opens it in Device Hub.")
        case .closedForScreens:
            String(localized: "Closed, for its closed screenshots on the cover display; AppLocalizer opens it for the open ones.")
        case .closing:
            String(localized: "Its closed screenshots are next: AppLocalizer is restarting it, which closes it…")
        case .opening:
            String(localized: "Opening iPhone Duo in Device Hub…")
        case .needsAccessibility:
            String(localized: """
            Closed: allow AppLocalizer in Privacy & Security › Accessibility, and it opens iPhone Duo itself. It only presses \
            Open in Device Hub.
            """)
        case .helperCantOpen:
            String(localized: "Closed: save the helper again so AppLocalizer can open it itself, or open it in Device Hub.")
        case let .couldntOpen(reason):
            String(localized: "Closed: AppLocalizer couldn’t open it (\(reason)). Open it in Device Hub.")
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
