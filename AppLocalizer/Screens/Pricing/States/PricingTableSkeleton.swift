//
//  PricingTableSkeleton.swift
//  AppLocalizer
//

import SwiftUI

/// Placeholder rows while a product's prices load (first visit and ⌘R),
/// under the column titles the matrix will show.
struct PricingTableSkeleton: View {
    let columns: [PriceColumn]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.medium) {
                ForEach(columns, id: \.self) { column in
                    Text(column.title)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .frame(maxWidth: column == .territory ? 170 : .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, Spacing.small)
            .frame(height: Metrics.tableHeaderHeight)
            .overlay(alignment: .bottom) { Divider() }
            ForEach(0..<14, id: \.self) { _ in
                HStack(spacing: Spacing.medium) {
                    SkeletonBlock(width: 20, height: 12)
                    SkeletonBlock(width: 120)
                    Spacer(minLength: Spacing.xxLarge)
                    ForEach(0..<4, id: \.self) { _ in SkeletonBlock(width: 70) }
                    SkeletonBlock(width: 160)
                    SkeletonBlock(width: 90)
                }
                .padding(.horizontal, Spacing.small)
                .frame(height: Metrics.tableRowHeight)
            }
        }
        // Rows that don't fit are cut off rather than raising the window's
        // minimum height: under ⌘R's filter bar, whose wrapping changes its
        // height, that minimum never settled and AppKit's layout crashed.
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Loading prices"))
        .accessibilityIdentifier("pricing.skeleton")
    }
}

#Preview {
    PricingTableSkeleton(columns: PriceColumnPreset.suggestions.columns)
        .frame(width: 900, height: 500)
}
