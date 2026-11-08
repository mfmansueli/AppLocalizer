//
//  RetentionArtworkView.swift
//  AppLocalizer
//

import SwiftUI

/// A retention image, filling its frame: the sample art, a file on this
/// Mac, or the Asset Library's thumbnail.
struct RetentionArtworkView: View {
    let image: RetentionImage

    var body: some View {
        Group {
            if let sample = image.sampleArtwork {
                RetentionSampleArtwork(name: sample)
            } else if let url = image.localPath.map({ URL(fileURLWithPath: $0) }) ?? image.thumbnailURL(width: 320) {
                AsyncImage(url: url) { phase in
                    if let loaded = phase.image {
                        loaded.resizable().scaledToFill()
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipped()
        .accessibilityElement()
        .accessibilityLabel(Text(image.name))
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Palette.fill2)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(Palette.label3)
            }
    }
}
