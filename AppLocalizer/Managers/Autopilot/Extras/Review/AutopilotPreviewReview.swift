//
//  AutopilotPreviewReview.swift
//  AppLocalizer
//

import Foundation

/// Watch the App Preview: the version the person is watching (1, then 2,
/// 3… for each revision from the design source), how it's cut, what each
/// revision changed, a change asked for and not made yet, and a remake
/// AppLocalizer is doing (new music, a revision).
struct AutopilotPreviewReview: Codable, Hashable, Sendable {
    var version = 1
    var cut = AppPreviewCut()
    /// Newest last.
    var revisions: [AutopilotPreviewRevision] = []
    /// Ask for changes, waiting for `revise_app_preview`.
    var request: AutopilotRevisionRequest?
    /// The App Previews are being made again.
    var remake: AutopilotPreviewRemake?

    /// Approve App Preview, Ask and the music wait.
    var isBusy: Bool { request != nil || remake != nil }
}
