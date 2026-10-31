//
//  DeviceScreen.swift
//  AppLocalizer
//

import Foundation

/// One screenshot of a device with screens of its own: Apple Watch's
/// "Mood check-in", or Apple Vision Pro's "Today", which carries the set's
/// first caption.
struct DeviceScreen: Codable, Hashable, Sendable {
    var name: String
    /// The set slot whose caption (and template slot) it uses; nil when it
    /// has no caption (Apple Watch).
    var captionSlot: Int?
}
