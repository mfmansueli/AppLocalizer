//
//  AppPreviewScreen.swift
//  AppLocalizer
//

import Foundation

/// One of the plan's screens as the App Preview captions it, in one
/// language.
struct AppPreviewScreen: Hashable, Sendable {
    var id: String
    /// That language's caption; empty draws no caption.
    var headline: String
}
