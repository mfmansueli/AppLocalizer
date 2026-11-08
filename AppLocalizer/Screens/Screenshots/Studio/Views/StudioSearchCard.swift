//
//  StudioSearchCard.swift
//  AppLocalizer
//

import SwiftUI

/// "In search results": the first three screenshots (two on iPad) at
/// search size, under the app's row; a click opens one full size.
struct StudioSearchCard: View {
    let app: StoreApp
    let preview: StudioPreview
    let appearance: StoreAppearance
    let image: (StudioShot) -> CGImage?
    /// For the new set's search results artwork; nil shows the screenshots.
    var studio: ScreenshotStudioModel?

    var body: some View {
        Card {
            Text("In search results")
                .font(.headline)
            VStack(alignment: .leading, spacing: Spacing.small) {
                StoreProductHeader(app: app, preview: preview, iconSize: 40, compact: true)
                if let studio, let artwork = studio.extrasPreview?.search {
                    // Second after the header, first when it's the only one.
                    Button { studio.openArtwork(at: artwork.kind == .wide || studio.extrasPreview?.header == nil ? 0 : 1) } label: {
                        ArtworkThumbnail(
                            studio: studio, kind: artwork.kind, template: artwork.template, locale: artwork.locale,
                            headline: artwork.headline, slots: artwork.slots, captures: artwork.captures, width: 300,
                            shows: artwork.shows, isMotion: artwork.isMotion, page: artwork.page
                        )
                    }
                    .buttonStyle(.plain)
                    .help(Text("Click to view larger"))
                    .accessibilityIdentifier("studio.search.artwork")
                } else {
                    HStack(alignment: .top, spacing: Spacing.xSmall) {
                        ForEach(Array(preview.searchShots.enumerated()), id: \.element.id) { index, shot in
                            let view = StudioShotImage(image: image(shot), width: width, aspect: shot.aspect)
                            if let studio {
                                Button { studio.openSearch(at: index) } label: { view }
                                    .buttonStyle(.plain)
                                    .help(Text("Click to view larger"))
                                    .accessibilityLabel(Text("Search result screenshot \(index + 1)"))
                                    .accessibilityIdentifier("studio.search.shot.\(index)")
                            } else {
                                view
                            }
                        }
                    }
                }
            }
            .padding(Spacing.medium)
            .environment(\.layoutDirection, preview.isRightToLeft ? .rightToLeft : .leftToRight)
            .environment(\.colorScheme, appearance.colorScheme)
            .background(appearance == .dark ? Color(white: 0.07) : Color.white, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            Text(studio?.extrasPreview?.search == nil ? preview.searchNote : StudioExtrasPreview.searchNote)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .accessibilityIdentifier("studio.search.note")
        }
        .accessibilityIdentifier("studio.search")
    }

    private var width: CGFloat {
        switch preview.displayType {
        case .iPad: 150
        case .iPhoneDuo: 125
        case .visionPro, .mac: 200
        default: 82
        }
    }
}
