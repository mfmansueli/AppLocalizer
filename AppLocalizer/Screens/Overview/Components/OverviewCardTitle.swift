//
//  OverviewCardTitle.swift
//  AppLocalizer
//

import SwiftUI

/// The small grey heading at the top of an overview card.
struct OverviewCardTitle: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(Palette.label2)
        .accessibilityAddTraits(.isHeader)
    }
}
