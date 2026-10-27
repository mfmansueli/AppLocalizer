//
//  ScreenshotViewerTarget.swift
//  AppLocalizer
//

import Foundation

/// The cell the full-size viewer shows: a locale and a slot on the current
/// display type.
struct ScreenshotViewerTarget: Identifiable, Hashable, Sendable {
    var locale: String
    var slot: Int

    var id: String { "\(locale)|\(slot)" }
}
