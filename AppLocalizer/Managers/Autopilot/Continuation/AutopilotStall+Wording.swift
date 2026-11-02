//
//  AutopilotStall+Wording.swift
//  AppLocalizer
//

import Foundation

/// What the sheet says when nobody works on a run: the notice above
/// Continue, the footer and the stage's row, in the stage's own words
/// (captures at Capture, directions at Design, captions at Localize).
/// Only a stop with work left, or a long silence, looks like a problem: a
/// paused run (AppLocalizer was closed) or Claude Code's turn after the
/// person's doesn't.
extension AutopilotStall {
    /// A stop or a silence, drawn as a warning; a pause isn't one.
    var isWarning: Bool {
        switch self {
        case .ended, .quiet: true
        case .notRunning, .handedBack: false
        }
    }

    /// The notice's headline: "Claude Code stopped with 113 captures left."
    func headline(of run: AutopilotRun, now: Date) -> String {
        let left = Self.workLeft(in: run)
        switch self {
        case .ended:
            return String(localized: "Claude Code stopped with \(left).")
        case .notRunning:
            return String(localized: "Paused when AppLocalizer closed, with \(left).")
        case .handedBack:
            return String(localized: "It’s Claude Code’s turn again, with \(left).")
        case let .quiet(since):
            let minutes = max(Int(now.timeIntervalSince(since) / 60), 1)
            return String(localized: "Nothing has arrived for \(minutes) minutes, with \(left). If Claude Code stopped, continue it here.")
        }
    }

    /// The footer's line, next to Continue.
    func footer(of run: AutopilotRun) -> String {
        let left = Self.workLeft(in: run)
        switch self {
        case .handedBack:
            return String(localized: "It’s Claude Code’s turn again. Continue starts it where the run is.")
        case .notRunning:
            return String(localized: "Paused when AppLocalizer closed, with \(left). Continue picks it up where it is.")
        case .ended, .quiet:
            return String(localized: "Claude Code isn’t working on this run, with \(left). Continue picks it up where it stopped.")
        }
    }

    /// The stage's row: red for a stop or a silence, plain for a pause.
    var stageNote: String? {
        switch self {
        case .handedBack: nil
        case .notRunning: String(localized: "Paused · Continue picks it up")
        case .quiet: String(localized: "Nothing new for a while")
        case .ended: String(localized: "Claude Code stopped")
        }
    }

    /// Under Continue: what continuing keeps.
    static func continueNote(for run: AutopilotRun) -> String {
        switch run.stage {
        case .design:
            String(localized: "Continue starts Claude Code again where the run is: the directions that arrived stay.")
        case .localize:
            String(localized: "Continue starts Claude Code again where the run is: it writes the captions that are missing or too long.")
        default:
            String(localized: """
            Continue starts Claude Code again where the run is: what’s captured stays, and a device this Mac can’t run \
            becomes one problem for the device, so the rest goes on.
            """)
        }
    }

    /// "113 captures left", "3 directions still to design", "your changes
    /// still to make", "65 captions still to write".
    static func workLeft(in run: AutopilotRun) -> String {
        switch run.stage {
        case .design:
            if run.revision != nil { return String(localized: "your changes still to make") }
            let left = run.directionsLeft
            return left == 1 ? String(localized: "1 direction still to design") : String(localized: "\(left) directions still to design")
        case .localize:
            return String(localized: "\(AutopilotCaptionWork.captions(run.overflows.count)) still to write")
        default:
            let left = run.capturesLeft
            return left == 1 ? String(localized: "1 capture left") : String(localized: "\(left) captures left")
        }
    }
}
