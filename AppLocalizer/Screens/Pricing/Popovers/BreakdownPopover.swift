//
//  BreakdownPopover.swift
//  AppLocalizer
//

import SwiftUI

/// How a territory's proposed price comes about, one line per step, with
/// the nearby price points to pick by hand.
struct BreakdownPopover: View {
    let row: PricingRow
    let nearby: [PricePoint]
    let isExcluded: Bool
    let onPick: (Decimal) -> Void
    let onBackToSuggestion: () -> Void
    let onResetToEqualized: () -> Void
    let onToggleExclusion: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(spacing: Spacing.small) {
                FlagTile(regionCode: row.territory.alpha2)
                Text("Price breakdown · \(row.territory.name)")
                    .font(.headline)
                Spacer(minLength: Spacing.medium)
                Text(provenance)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .lineLimit(1)
            }
            PriceBreakdownSteps(summary: summary, steps: steps)
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Nearby Price Points")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.label2)
                NearbyPriceChips(territoryID: row.id, points: nearby, current: row.shownPrice, currency: row.currency, onPick: onPick)
            }
            HStack(spacing: Spacing.small) {
                if row.origin == .manual {
                    Button("Back to Suggestion", action: onBackToSuggestion)
                        .accessibilityIdentifier("pricing.breakdown.backToSuggestion")
                }
                Spacer(minLength: 0)
                Button("Reset to Equalized", action: onResetToEqualized)
                    .accessibilityIdentifier("pricing.breakdown.resetToEqualized")
                Button(isExcluded ? String(localized: "Include in Index") : String(localized: "Exclude from Index"), action: onToggleExclusion)
                    .disabled(row.isBase)
                    .accessibilityIdentifier("pricing.breakdown.exclude")
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("pricing.breakdown.done")
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
        }
        .padding(Spacing.large)
        .frame(width: 420)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.breakdownPopover")
    }

    private var usesSuggestion: Bool { !row.usesCustomStrategy && row.recommendation != nil }

    private var summary: String {
        usesSuggestion ? row.recommendation?.summary ?? row.calculation.summary : row.calculation.summary
    }

    private var steps: [String] {
        usesSuggestion ? row.recommendation?.steps ?? row.calculation.steps : row.calculation.steps
    }

    private var provenance: String {
        if row.origin == .manual { return String(localized: "Edited manually") }
        if row.usesCustomStrategy { return String(localized: "Custom strategy · \(row.calculation.provenance.label)") }
        return String(localized: "Recommended")
    }
}
