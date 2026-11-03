//
//  ArtworkAppLabel.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The app's icon and name under the headline, in artwork pixels.
struct ArtworkAppLabel: Hashable, Sendable {
    var iconFrame: CGRect
    var name: LayoutTextLine
}
