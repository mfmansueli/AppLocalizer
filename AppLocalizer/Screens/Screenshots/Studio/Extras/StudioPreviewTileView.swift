//
//  StudioPreviewTileView.swift
//  AppLocalizer
//

import SwiftUI

/// The App Preview first among the preview's screenshots: its poster with
/// a chip ("New", or the language it's in), which plays it full size.
struct StudioPreviewTileView: View {
    @Bindable var studio: ScreenshotStudioModel
    let tile: StudioPreviewTile
    let width: CGFloat

    var body: some View {
        Button {
            studio.openGallery(at: 0)
        } label: {
            AppPreviewPosterView(
                template: tile.template, headline: tile.headline,
                capture: tile.capture.flatMap { studio.screenshots.captureImages.image(for: $0, width: 480) },
                length: tile.length, width: width
            )
            .overlay(alignment: .topLeading) {
                StudioArtworkChip(text: tile.chip).padding(Spacing.xxSmall)
            }
        }
        .buttonStyle(.plain)
        .task(id: tile.capture) {
            if let capture = tile.capture { studio.screenshots.captureImages.request([capture], width: 480) }
        }
        .help(Text("Play the App Preview"))
        .accessibilityLabel(Text("App Preview, \(tile.length), \(tile.chip)"))
        .accessibilityIdentifier("studio.store.appPreview")
    }
}
