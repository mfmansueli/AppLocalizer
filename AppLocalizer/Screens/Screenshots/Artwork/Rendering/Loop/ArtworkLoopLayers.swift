//
//  ArtworkLoopLayers.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The parts of a motion loop that don't change between frames, drawn
/// once at full size: the background, the phones (on clear, so they can
/// float) and the text with the icon and name (on clear). Each frame lays
/// the scene and the floating phones between them.
struct ArtworkLoopLayers: Sendable {
    var background: CGImage
    var phones: CGImage?
    var text: CGImage

    /// Frame `phase` (0–1) of the loop in `context`, which has Core
    /// Graphics' bottom-left origin.
    nonisolated func draw(_ layout: ArtworkLayout, phase: Double, in context: CGContext) {
        let size = layout.size
        let full = CGRect(origin: .zero, size: size)
        context.draw(background, in: full)
        if let scene = layout.scene {
            context.saveGState()
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
            ArtworkScenePainter.draw(scene, in: context, size: size, phase: phase)
            context.restoreGState()
        }
        if let phones {
            // Up on the page is up here too: the offset's sign flips.
            let lift = -ArtworkScene.floatOffset(phase, height: size.height)
            context.draw(phones, in: full.offsetBy(dx: 0, dy: lift))
        }
        context.draw(text, in: full)
    }
}
