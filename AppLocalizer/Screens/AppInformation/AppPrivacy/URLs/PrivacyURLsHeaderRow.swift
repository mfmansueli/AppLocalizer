//
//  PrivacyURLsHeaderRow.swift
//  AppLocalizer
//

import SwiftUI

/// The table's column titles.
struct PrivacyURLsHeaderRow: View {
    var body: some View {
        HStack(spacing: Spacing.small) {
            Text("Locale")
                .frame(width: PrivacyURLsRow.localeWidth, alignment: .leading)
            Text("Privacy Policy URL · required")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("User Privacy Choices URL · optional")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Palette.label2)
        .lineLimit(1)
        .padding(.horizontal, Spacing.large)
        .frame(height: Metrics.tableHeaderHeight)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
