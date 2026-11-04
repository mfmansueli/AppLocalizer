//
//  ArtworkWebRender.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// A Claude Design page rendered in one language: the image (opaque, the
/// request's width), what's behind the text (small, for contrast), and
/// where everything landed.
struct ArtworkWebRender: Sendable {
    var image: CGImage
    /// The page with the filled-in text hidden, `ArtworkPixels.maximumWidth`
    /// wide; nil when it wasn't asked for.
    var behindText: CGImage?
    var measure: ArtworkWebMeasure
    /// The markers whose box moves during the loop (text and icon).
    var moving: [ArtworkWebMarker] = []
}
