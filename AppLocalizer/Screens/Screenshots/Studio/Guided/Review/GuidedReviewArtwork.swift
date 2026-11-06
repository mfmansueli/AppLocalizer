//
//  GuidedReviewArtwork.swift
//  AppLocalizer
//

import SwiftUI

/// The new set's header and search images in Review & push, in the
/// language chosen: the header, and the search result beside it.
struct GuidedReviewArtwork: View {
    @Bindable var studio: ScreenshotStudioModel
    let locale: String
    let width: CGFloat

    var body: some View {
        let items = studio.guidedArtwork(locale: locale)
        HStack(alignment: .bottom, spacing: 10) {
            if items.isEmpty {
                Text("The header and search images are on their way.")
                    .foregroundStyle(Palette.label2)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
            ForEach(items, id: \.kind) { item in
                ArtworkThumbnail(
                    studio: studio, kind: item.kind, template: item.template, locale: item.locale, headline: item.headline,
                    slots: item.slots, captures: item.captures, width: itemWidth(item, count: items.count), shows: item.shows,
                    isMotion: item.isMotion, page: item.page
                )
                .accessibilityLabel(Text(item.kind == .search ? "Search results" : "Header"))
                .accessibilityIdentifier("autopilot.guided.review.artwork.\(item.kind.rawValue)")
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 300)
        .modifier(GuidedSelectableCard(padding: 0))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("autopilot.guided.review.artwork")
    }

    /// The header takes about 70% of the room beside the search image.
    private func itemWidth(_ item: StudioArtworkItem, count: Int) -> CGFloat {
        let room = max(width - Spacing.medium * 2 - 10, 200)
        guard count > 1 else { return min(room, 560).rounded() }
        return (item.kind == .search ? room * 0.3 : room * 0.7).rounded(.down)
    }
}
