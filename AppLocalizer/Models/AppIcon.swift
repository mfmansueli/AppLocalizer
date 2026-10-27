//
//  AppIcon.swift
//  AppLocalizer
//

import Foundation

/// How an app's icon is drawn in the library and the overview. Apps without
/// one get a letter tile.
enum AppIcon: Hashable, Sendable {
    /// The icon image App Store Connect serves for the app's latest build.
    case remote(URL)
    /// An SF Symbol on a vertical gradient (sample data in DEBUG scenes).
    case symbol(String, top: UInt32, bottom: UInt32)
}
