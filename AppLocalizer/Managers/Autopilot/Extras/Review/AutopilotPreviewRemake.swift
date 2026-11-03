//
//  AutopilotPreviewRemake.swift
//  AppLocalizer
//

import Foundation

/// The App Previews being made again: with other music (no design step),
/// or as a revision's new version.
struct AutopilotPreviewRemake: Codable, Hashable, Sendable {
    enum Reason: Codable, Hashable, Sendable {
        /// "Calm piano".
        case music(String)
        /// The version it becomes.
        case revision(Int)
    }

    var reason: Reason
    var done = 0
    var total = 0

    /// "Mixing again with Calm piano · 1 of 2", "Making App Preview v2 · 1 of 2".
    var title: String {
        let what = switch reason {
        case let .music(name): String(localized: "Mixing again with \(name)")
        case let .revision(version): String(localized: "Making App Preview v\(version)")
        }
        guard total > 1 else { return what }
        return what + " · " + String(localized: "\(done) of \(total)")
    }
}
