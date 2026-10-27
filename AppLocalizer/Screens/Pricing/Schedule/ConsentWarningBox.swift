//
//  ConsentWarningBox.swift
//  AppLocalizer
//

import SwiftUI

/// The schedule sheet's warning about increases: how many territories go
/// up and how many existing subscribers they have, why that matters, and
/// one line per territory.
struct ConsentWarningBox: View {
    let consent: PriceIncreaseConsent

    /// More rows than this scroll inside the box.
    private let visibleRowLimit = 8

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Label {
                Text(consent.title)
                    .font(.callout.weight(.semibold))
                    .monospacedDigit()
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Palette.warningMark)
            }
            Text("""
            Apple tells existing subscribers before an increase. In some territories, and above Apple’s limits, they \
            have to agree or the subscription ends at renewal. Keeping their price avoids that.
            """)
            .font(.callout)
            .foregroundStyle(Palette.label2)
            .fixedSize(horizontal: false, vertical: true)
            if consent.items.count > visibleRowLimit {
                ScrollView { rows }
                    .frame(height: CGFloat(visibleRowLimit) * 29)
            } else {
                rows
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.warningTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.schedule.consent")
    }

    private var rows: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.small, verticalSpacing: 0) {
            ForEach(consent.items) { item in
                Divider().gridCellColumns(4)
                GridRow {
                    Text(item.territory.name)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    Text(item.pricesText)
                        .foregroundStyle(Palette.label2)
                        .lineLimit(1)
                    DeltaPill(percent: item.change.percent)
                    Text(item.subscribersText ?? "")
                        .gridColumnAlignment(.trailing)
                }
            }
        }
        .font(.callout)
        .monospacedDigit()
    }
}
