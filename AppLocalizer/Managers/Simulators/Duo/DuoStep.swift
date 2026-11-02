//
//  DuoStep.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer does about iPhone Duo's simulator after looking at it
/// (`DuoWatcher`). Opening it is the person's, in Device Hub; starting it
/// and restarting a stuck one are AppLocalizer's. A stuck Duo's SpringBoard
/// crashes whenever an app opens, and its inner display shows only a
/// spinner; a restart clears it, and it comes back closed.
enum DuoStep: Hashable, Sendable {
    /// Nothing to do: it's open, or closed until the person opens it.
    case wait
    /// It isn't running: start it.
    case start
    /// It's stuck: shut it down and start it again.
    case restart(Reason)
    /// Still stuck after `maximumRestarts` restarts.
    case giveUp(Reason)

    enum Reason: Hashable, Sendable {
        /// Its SpringBoard crashed since it started.
        case springBoardCrashed
        /// Its inner display showed only a spinner for `spinnerLimit`.
        case spinner
    }

    /// Long enough for it to start, or for the person to open it.
    static let spinnerLimit: TimeInterval = 90

    /// Restarts in a row before it's left to the person.
    static let maximumRestarts = 2

    /// What one look found. `inner` is nil when it isn't running or the
    /// inner display couldn't be read; `spinnerSince`, when the spinner was
    /// first seen.
    struct Look: Hashable, Sendable {
        var isBooted: Bool
        var inner: DuoInnerDisplay?
        var crashedSinceStart = false
        var spinnerSince: Date?
    }

    /// The step after `look`. `mayStart`: AppLocalizer may start it (during
    /// a run, not while the plan is only being looked at).
    static func next(after look: Look, restarts: Int, mayStart: Bool, now: Date) -> DuoStep {
        guard look.isBooted else { return mayStart ? .start : .wait }
        guard look.inner != .showing else { return .wait }
        let reason: Reason? = if look.crashedSinceStart {
            .springBoardCrashed
        } else if look.inner == .spinner, let since = look.spinnerSince, now.timeIntervalSince(since) >= spinnerLimit {
            .spinner
        } else {
            nil
        }
        guard let reason else { return .wait }
        return restarts < maximumRestarts ? .restart(reason) : .giveUp(reason)
    }
}
