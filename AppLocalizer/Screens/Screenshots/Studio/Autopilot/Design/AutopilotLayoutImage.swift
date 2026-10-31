//
//  AutopilotLayoutImage.swift
//  AppLocalizer
//

import SwiftUI

/// A direction's screenshot drawn from its layout at `width` points, the
/// way the renderer paints it.
struct AutopilotLayoutImage: View {
    let layout: ScreenshotLayout
    let capture: CGImage?
    let width: CGFloat

    var body: some View {
        let scale = width / layout.canvas.width
        let height = (layout.canvas.height * scale).rounded()
        Canvas(opaque: true, rendersAsynchronously: false) { context, _ in
            context.scaleBy(x: scale, y: scale)
            ScreenshotPainter(layout: layout, capture: capture).draw(in: &context)
        }
        .frame(width: width, height: height)
        .environment(\.layoutDirection, .leftToRight)
        .clipShape(RoundedRectangle(cornerRadius: max(3, width * 0.05), style: .continuous))
        .accessibilityHidden(true)
    }
}
