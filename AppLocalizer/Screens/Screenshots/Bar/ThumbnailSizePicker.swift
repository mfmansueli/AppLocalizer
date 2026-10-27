//
//  ThumbnailSizePicker.swift
//  AppLocalizer
//

import SwiftUI

/// S / M / L: the Sets thumbnails' size.
struct ThumbnailSizePicker: View {
    @Binding var selection: ThumbnailSize

    var body: some View {
        Picker(String(localized: "Thumbnail size"), selection: $selection) {
            ForEach(ThumbnailSize.allCases) { size in
                Text(size.title)
                    .accessibilityLabel(Text(size.accessibilityTitle))
                    .tag(size)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .accessibilityIdentifier("screenshots.thumbnailSize")
    }
}
