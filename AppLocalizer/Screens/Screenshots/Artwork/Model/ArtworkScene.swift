//
//  ArtworkScene.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// What the header and search artwork draws over its background besides
/// the app: soft light (a dusk fade and a glow), and for "No app: a
/// scene", a landscape in the template's colors (stars, a moon, two
/// hills). A motion loop moves it slowly; `ArtworkScenePainter` draws it at
/// any moment of the loop, the first and the last the same.
struct ArtworkScene: Hashable, Sendable {
    var kind: AutopilotArtworkKind
    /// Stars, the moon and hills; without them, only the light.
    var hasLandscape: Bool
    /// It moves: the light drifts, the moon rises, the stars twinkle.
    var isMotion: Bool
    /// The background is light: darker stars and hills, a white glow.
    var isLight: Bool
    var isMirrored: Bool

    /// One star: where it is (0–100 across and down) and how big, in
    /// hundredths of the width.
    struct Star: Hashable, Sendable {
        var x: Double
        var y: Double
        var size: Double
    }

    /// The canvas's twelve stars.
    static let starSpots: [Star] = [
        Star(x: 6, y: 18, size: 1.6), Star(x: 13, y: 34, size: 1.1), Star(x: 21, y: 12, size: 1.3), Star(x: 29, y: 27, size: 0.9),
        Star(x: 37, y: 8, size: 1.2), Star(x: 44, y: 22, size: 0.8), Star(x: 57, y: 14, size: 1.0), Star(x: 64, y: 30, size: 1.4),
        Star(x: 72, y: 9, size: 0.9), Star(x: 81, y: 24, size: 1.2), Star(x: 88, y: 13, size: 1.5), Star(x: 94, y: 31, size: 0.9),
    ]

    /// The loop runs this long; everything in it repeats within it.
    static let loopSeconds = Double(AutopilotArtworkMotion.loopSeconds)

    /// 0 at the start and the end of the loop, 1 halfway: the slow drift
    /// back and forth.
    static func drift(_ phase: Double) -> Double {
        (1 - cos(2 * .pi * phase)) / 2
    }

    /// The phones float up and back down every 10 seconds, by 2.6% of the
    /// height.
    static func floatOffset(_ phase: Double, height: CGFloat) -> CGFloat {
        -0.026 * height * CGFloat(drift(phase * 2))
    }
}
