//
//  ArtworkReadText.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A line of text Vision read in a render, with where it is in artwork
/// pixels from the top left.
struct ArtworkReadText: Hashable, Sendable {
    var text: String
    var frame: CGRect
    var confidence: Double
}
