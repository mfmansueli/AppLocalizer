//
//  LiveScreenshotImageError.swift
//  AppLocalizer
//

import Foundation

/// Why a live screenshot's file can't be read to keep it before a push
/// replaces it.
enum LiveScreenshotImageError: Error, Hashable, Sendable {
    /// App Store Connect has no image for it: its upload never finished or
    /// Apple couldn't process it. There's nothing to keep.
    case noImage
    /// Uploaded and still being processed: its image isn't there yet.
    case stillProcessing
}
