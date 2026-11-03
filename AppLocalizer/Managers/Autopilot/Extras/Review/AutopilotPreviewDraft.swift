//
//  AutopilotPreviewDraft.swift
//  AppLocalizer
//

import Foundation

/// What the design source sends for the App Preview's next version: the
/// cut, what changed, and optionally a new look and a library track.
struct AutopilotPreviewDraft: Hashable, Sendable {
    var cut: AppPreviewCut
    /// "Slower pace, starts with Search".
    var changes: String
    var look: ScreenshotTemplate?
    var track: AppPreviewTrack?
    /// "Claude Code".
    var client: String
}
