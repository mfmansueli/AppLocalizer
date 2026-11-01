//
//  StudioSearchCard.swift
//  AppLocalizer
//

import SwiftUI

/// "In search results": the first three screenshots (two on iPad) at
/// search size, under the app's row.
struct StudioSearchCard: View {
    let app: StoreApp
    let preview: StudioPreview
    let appearance: StoreAppearance
    let image: (StudioShot) -> CGImage?

    var body: some View {
        Card {
            Text("In search results")
                .font(.headline)
            VStack(alignment: .leading, spacing: Spacing.small) {
                StoreProductHeader(app: app, preview: preview, iconSize: 40, compact: true)
                HStack(alignment: .top, spacing: Spacing.xSmall) {
                    ForEach(preview.searchShots) { shot in
                        StudioShotImage(image: image(shot), width: width, aspect: shot.aspect)
                    }
                }
            }
            .padding(Spacing.medium)
            .environment(\.layoutDirection, preview.isRightToLeft ? .rightToLeft : .leftToRight)
            .environment(\.colorScheme, appearance.colorScheme)
            .background(appearance == .dark ? Color(white: 0.07) : Color.white, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
            Text(preview.searchNote)
                .font(.callout)
                .foregroundStyle(Palette.label2)
        }
        .accessibilityIdentifier("studio.search")
    }

    private var width: CGFloat {
        switch preview.displayType {
        case .iPad: 150
        case .iPhoneDuo: 125
        case .visionPro: 200
        default: 82
        }
    }
}
