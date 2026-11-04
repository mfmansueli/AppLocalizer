//
//  ExtrasPushActivity.swift
//  AppLocalizer
//

import Foundation

/// One item in flight and how far its step has got, for the progress
/// lines: the bytes it sent while it uploads, how long Apple has been
/// processing it and how often that was checked.
struct ExtrasPushActivity: Hashable, Sendable {
    var itemID: ExtrasPushItem.ID
    /// When the item's turn came.
    var startedAt: Date
    /// When its current step (getting ready, uploading, processing,
    /// placing) started.
    var stepStartedAt: Date
    /// Bytes of the file sent so far, of `totalBytes` (0 until it's read).
    var sentBytes = 0
    var totalBytes = 0
    /// How many times Apple's processing state was checked.
    var checks = 0
}
