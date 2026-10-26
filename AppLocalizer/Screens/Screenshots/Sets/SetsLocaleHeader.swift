//
//  SetsLocaleHeader.swift
//  AppLocalizer
//

import SwiftUI

/// A row's locale column: flag, name, Primary, and the row's summary
/// ("1 check failed · 4 not pushed", "UI not localized", "Live").
struct SetsLocaleHeader: View {
    let row: SetsRow

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: Spacing.xSmall) {
                FlagTile(regionCode: row.locale.regionCode)
                    .frame(width: 20)
                Text(row.locale.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                if row.isPrimary {
                    Pill(text: String(localized: "Primary"))
                        .fixedSize()
                }
            }
            Text(row.summary.text)
                .font(.caption)
                .foregroundStyle(row.summary.isFailing ? Palette.danger : Palette.label2)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 26)
        }
        .accessibilityElement(children: .combine)
    }
}
