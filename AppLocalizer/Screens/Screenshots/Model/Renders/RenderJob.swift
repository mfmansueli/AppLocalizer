//
//  RenderJob.swift
//  AppLocalizer
//

import Foundation

/// What one render needs: the template version, the caption and the
/// capture for a locale × display type × slot, and its precomputed layout.
/// Two jobs with the same key make the same PNG.
struct RenderJob: Hashable, Sendable, Identifiable {
    var key: RenderKey
    var layout: ScreenshotLayout
    var capture: ScreenshotCapture?
    /// iPhone Duo's cover display beside the inner one (both, side by side).
    var companion: ScreenshotCapture?

    var id: RenderKey { key }
}
