//
//  StorePageCard.swift
//  AppLocalizer
//

import SwiftUI

/// Store-page locales, how complete they are, and what's missing,
/// machine-translated or over a limit.
struct StorePageCard: View {
    let summary: StorePageSummary
    let onOpen: () -> Void

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "Store page"), systemImage: "globe")
            Text("\(summary.localeCount) of \(summary.totalLocaleCount) locales · \(summary.completeness.formatted(.percent.precision(.fractionLength(0))))")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            MeterBar(fraction: summary.completeness, height: 8)
            FlowLayout(spacing: 6) {
                Pill(text: String(localized: "\(summary.missingCount) missing"), style: .outline)
                Pill(text: String(localized: "\(summary.machineTranslatedCount) machine-translated"), style: .machineTranslated)
                Pill(text: String(localized: "\(summary.overLimitCount) over the limit"), style: .danger)
            }
            Button("Open Store Page", action: onOpen)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.storePageCard")
    }
}
