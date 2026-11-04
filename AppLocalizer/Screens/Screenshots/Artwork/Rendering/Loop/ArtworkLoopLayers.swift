//
//  ArtworkLoopLayers.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// The parts of a motion loop that don't change between frames, drawn
/// once at full size: the background, the phones (on clear, so they can
/// float) and the text with the icon and name (on clear). Each frame lays
/// the scene and the floating phones between them. `prepared` makes them
/// cheap to draw 600 times (`ArtworkLoopBitmap`): the movie's pixel format,
/// and the phones and text cut to where they are.
struct ArtworkLoopLayers: Sendable {
    var background: CGImage
    var phones: CGImage?
    var text: CGImage?
    /// Where the phones and the text go, in Core Graphics' bottom-left
    /// origin; nil draws them over the whole frame.
    var phonesFrame: CGRect?
    var textFrame: CGRect?

    init(background: CGImage, phones: CGImage?, text: CGImage?, phonesFrame: CGRect? = nil, textFrame: CGRect? = nil) {
        self.background = background
        self.phones = phones
        self.text = text
        self.phonesFrame = phonesFrame
        self.textFrame = textFrame
    }

    /// The layers ready to draw every frame; empty layers are dropped. Nil
    /// when the background can't be redrawn.
    nonisolated static func prepared(background: CGImage, phones: CGImage?, text: CGImage) -> ArtworkLoopLayers? {
        guard let base = ArtworkLoopBitmap.prepare(background, opaque: true) else { return nil }
        let height = CGFloat(background.height)
        let cutPhones = phones.flatMap { ArtworkLoopBitmap.prepare($0, opaque: false) }
        let cutText = ArtworkLoopBitmap.prepare(text, opaque: false)
        return ArtworkLoopLayers(
            background: base.image, phones: cutPhones?.image, text: cutText?.image,
            phonesFrame: cutPhones.map { ArtworkLoopBitmap.flipped($0.bounds, height: height) },
            textFrame: cutText.map { ArtworkLoopBitmap.flipped($0.bounds, height: height) }
        )
    }

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
            context.draw(phones, in: (phonesFrame ?? full).offsetBy(dx: 0, dy: lift))
        }
        if let text {
            context.draw(text, in: textFrame ?? full)
        }
    }
}
