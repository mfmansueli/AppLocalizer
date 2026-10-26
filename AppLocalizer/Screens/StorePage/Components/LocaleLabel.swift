//
//  LocaleLabel.swift
//  AppLocalizer
//

import SwiftUI

/// A locale's row header: flag, name, and the Primary and RTL tags.
struct LocaleLabel: View {
    let locale: StoreLocale
    var isPrimary = false
    var showsTags = true

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            FlagTile(regionCode: locale.regionCode)
                .frame(width: 20)
            Text(locale.name)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
            if showsTags, isPrimary {
                Pill(text: String(localized: "Primary"))
            }
            if showsTags, locale.isRTL {
                Pill(text: String(localized: "RTL"), style: .outline)
                    .accessibilityLabel(Text("Right to left"))
            }
        }
        .accessibilityElement(children: .combine)
    }
}
