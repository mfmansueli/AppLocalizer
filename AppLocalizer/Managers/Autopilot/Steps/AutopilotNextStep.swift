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
    /// The plan has no screens yet: choose them (`update_capture_plan`).
    case chooseScreens
    /// Every screen is captured: record the App Preview's walkthroughs.
    case record(targets: [AutopilotRecordingTarget])
    /// Nothing to do yet; ask again later.
    case wait(reason: String, seconds: Int)
    /// Record these App Preview moments again (`rerecord_moment`), before
    /// the design step: the person asked at Pick.
    case recordAgain(screenIDs: [String])
    /// Design the directions (`get_design_brief`, then `propose_direction`).
    case design(remaining: Int)
    /// "Ask for changes": revise with `revise_direction`.
    case revise(note: String)
    /// Localize and check is done: animate the chosen header into the
    /// loop (the motion prompt), then `revise_artwork_concept`.
    case animateHeader(conceptID: String)
    /// "Ask for changes" on the header loop: its new version with
    /// `revise_artwork_concept`.
    case reviseLoop(note: String)
    /// "Ask for changes" on the App Preview: send the new cut with
    /// `revise_app_preview`.
    case revisePreview(note: String, review: AutopilotPreviewReview)
    /// Write or shorten these captions (`propose_captions` with the run).
    case writeCaptions([AutopilotOverflow])
    /// The header's and search image's own texts to write or shorten.
    case writeArtworkTexts([AutopilotArtworkTextNeed])
    /// A second header or search image for a Product Page Optimization
    /// test.
    case designVariant(ArtworkVariantRequest)
    /// Suggest screens the set is missing (`propose_screens`).
    case suggestScreens(AutopilotScreenRequest)
    /// The set waits in Review & Push.
    case done
}
