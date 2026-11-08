//
//  SlotPreviewImage.swift
//  AppLocalizer
//

import SwiftUI

/// A live preview of one slot, drawn from its layout at `width` points:
/// the template editor's canvas and strip, the caption editor's preview.
/// It paints the same way the renderer does, scaled, so it follows every
/// edit without making a render. With guides it draws the safe area
/// dashed in blue and the caption box, red when the caption overflows or
/// a glyph is missing.
struct SlotPreviewImage: View {
    let preview: SlotPreview
    let capture: CGImage?
    /// The phone behind on a Two phones slot.
    var companion: CGImage?
    let width: CGFloat
    var showsGuides = false

    var body: some View {
        let layout = preview.layout
        let scale = width / layout.canvas.width
        let height = (layout.canvas.height * scale).rounded()
        Canvas(opaque: true, rendersAsynchronously: false) { context, _ in
            context.scaleBy(x: scale, y: scale)
            ScreenshotPainter(layout: layout, capture: capture, companion: companion).draw(in: &context)
            if showsGuides { drawGuides(in: &context, scale: scale) }
        }
        .frame(width: width, height: height)
        .environment(\.layoutDirection, .leftToRight)
        .clipShape(RoundedRectangle(cornerRadius: max(4, width * 0.045), style: .continuous))
    }

    private func drawGuides(in context: inout GraphicsContext, scale: CGFloat) {
        let layout = preview.layout
        let line = 1 / scale
        context.stroke(
            Path(layout.safeArea),
            with: .color(Color.accentColor.opacity(0.9)),
            style: StrokeStyle(lineWidth: line, dash: [4 * line, 3 * line])
        )
        let boxColor = preview.hasCaptionProblem ? Palette.dangerMark : Color.accentColor
        context.stroke(Path(layout.captionBox), with: .color(boxColor), lineWidth: 1.5 * line)
    }
}
