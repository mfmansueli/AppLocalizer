//
//  TerritoryPricesCard.swift
//  AppLocalizer
//

import SwiftUI

/// How many territories use Apple's equalized price vs a custom one.
struct TerritoryPricesCard: View {
    let summary: PricingSummary

    var body: some View {
        Card {
            OverviewCardTitle(title: title)
            Text("\(summary.equalizedTerritoryCount) equalized · \(summary.customTerritoryCount) custom")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            MeterBar(fraction: fraction, height: 8)
            Text("Custom prices were set by hand or by an earlier push. \(total) territories in all.")
                .font(.subheadline)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("overview.territoryPricesCard")
    }

    private var title: String {
        guard let product = summary.reportedProductName else { return String(localized: "Territory prices") }
        return String(localized: "Territory prices · \(product)")
    }

    private var total: Int { summary.equalizedTerritoryCount + summary.customTerritoryCount }

    private var fraction: Double {
        total > 0 ? Double(summary.equalizedTerritoryCount) / Double(total) : 0
    }
}
