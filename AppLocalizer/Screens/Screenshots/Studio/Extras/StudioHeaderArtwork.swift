//
//  StudioHeaderArtwork.swift
//  AppLocalizer
//

import SwiftUI

/// The new set's product page header, full width on top of the page, with
/// a "New · header" chip; a click opens it full size.
struct StudioHeaderArtwork: View {
    @Bindable var studio: ScreenshotStudioModel
    let item: StudioArtworkItem
    let width: CGFloat

    var body: some View {
        Button { studio.openArtwork(at: 0) } label: {
            ArtworkThumbnail(
                studio: studio, kind: item.kind, template: item.template, locale: item.locale, headline: item.headline,
                slots: item.slots, captures: item.captures, width: width.rounded(), shows: item.shows, isMotion: item.isMotion
            )
        }
        .buttonStyle(.plain)
        .help(Text("Click to view larger"))
        .overlay(alignment: .topLeading) {
            StudioArtworkChip(text: String(localized: "New · header"))
                .padding(Spacing.small)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("studio.store.header")
    }
}
