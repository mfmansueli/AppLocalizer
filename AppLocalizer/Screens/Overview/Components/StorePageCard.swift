//
//  StorePageCard.swift
//  AppLocalizer
//

import SwiftUI

/// Store-page locales, how complete they are, and what's missing,
/// machine-translated or over a limit; and the languages the app supports
/// that the page doesn't have yet.
struct StorePageCard: View {
    let summary: StorePageSummary
    /// "12 · 3 more in the app" while the project has languages the App
    /// Store page doesn't, or "12 · 2 new to push" once they're added.
    var languagesText: String?
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
            if let languagesText {
                OverviewRow {
                    Text("Languages").foregroundStyle(Palette.label2)
                } value: {
                    Text(languagesText)
                        .monospacedDigit()
                }
                .accessibilityIdentifier("overview.storePageCard.languages")
            }
            Button("Open Store Page", action: onOpen)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.storePageCard")
    }
}
