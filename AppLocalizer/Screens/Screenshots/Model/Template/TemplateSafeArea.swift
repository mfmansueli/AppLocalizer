//
//  TemplateSafeArea.swift
//  AppLocalizer
//

import Foundation

/// `safe`: margins captions stay inside, as fractions of the canvas
/// (top and bottom of its height, sides of its width). The App Store
/// rounds the corners, so nothing important goes there.
struct TemplateSafeArea: Codable, Hashable, Sendable {
    var top: Double
    var side: Double
    var bottom: Double
}
