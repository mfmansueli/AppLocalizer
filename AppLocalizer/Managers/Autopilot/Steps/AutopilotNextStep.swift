//
//  AutopilotNextStep.swift
//  AppLocalizer
//

import Foundation

/// What AppLocalizer wants from the assistant next (`next_step`).
enum AutopilotNextStep: Hashable, Sendable {
    /// No run is waiting: the person starts one with Run Autopilot….
    case noRun
    /// Capture these, and capture again the problems the person retried
    /// with their fix.
    case capture(targets: [AutopilotCaptureTarget], retries: [AutopilotProblem])
    /// Nothing to do yet; ask again later.
    case wait(reason: String, seconds: Int)
    /// Design the directions (`get_design_brief`, then `propose_direction`).
    case design(remaining: Int)
    /// "Ask for changes": revise with `revise_direction`.
    case revise(note: String)
    /// Write or shorten these captions (`propose_captions` with the run).
    case writeCaptions([AutopilotOverflow])
    /// The set waits in Review & Push.
    case done
}
