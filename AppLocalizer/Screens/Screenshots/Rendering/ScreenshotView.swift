//
//  ScreenshotView.swift
//  AppLocalizer
//

import SwiftUI

/// One screenshot, drawn from its layout at the canvas's pixel size (one
/// point per pixel). `ScreenshotImageRenderer` turns it into the PNG that
/// gets uploaded; the app shows cached renders of it rather than drawing
/// it live in grids.
struct ScreenshotView: View {
    let layout: ScreenshotLayout
    let capture: CGImage?

    init(layout: ScreenshotLayout, capture: CGImage?) {
        self.layout = layout
        self.capture = capture
    }

    /// Lays the template out for one locale × display type × slot first.
    init(
        template: ScreenshotTemplate,
        caption: ScreenshotCaption?,
        capture: CGImage?,
        locale: StoreLocale,
        placement: ScreenshotCellKey,
        fonts: ScreenshotFontCatalog = .standard
    ) {
        layout = ScreenshotLayoutEngine(catalog: fonts).layout(
            template, slot: placement.slot, locale: locale, displayType: placement.displayType, caption: caption
        )
        self.capture = capture
    }

    var body: some View {
        Canvas(opaque: true, rendersAsynchronously: false) { context, _ in
            ScreenshotPainter(layout: layout, capture: capture).draw(in: &context)
        }
        .frame(width: layout.canvas.width, height: layout.canvas.height)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}
