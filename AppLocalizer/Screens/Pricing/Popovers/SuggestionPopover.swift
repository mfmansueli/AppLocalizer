//
//  SuggestionPopover.swift
//  AppLocalizer
//

import SwiftUI

/// Why a territory's price is suggested: today against the suggestion, the
/// reason, what it's based on and how sure it is.
struct SuggestionPopover: View {
    let row: PricingRow
    let recommendation: Recommendation
    let baseName: String
    let isApplied: Bool
    let onShowBreakdown: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header
            HStack(spacing: Spacing.small) {
                priceCard(
                    title: String(localized: "Today"),
                    price: row.current.customerPrice,
                    feelsLike: recommendation.feelsLikeText,
                    ratio: recommendation.ratioText,
                    delta: nil
                )
                priceCard(
                    title: String(localized: "Suggested"),
                    price: recommendation.price.customerPrice,
                    feelsLike: recommendation.feelsLikeSuggestedText,
                    ratio: recommendation.suggestedRatioText,
                    delta: PriceChange(old: row.current.customerPrice, new: recommendation.price.customerPrice).percent
                )
            }
            Text(recommendation.reason)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("What It’s Based On")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.label2)
                ForEach(recommendation.basis, id: \.self) { line in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                        Text(verbatim: "•").foregroundStyle(Palette.label3).accessibilityHidden(true)
                        Text(line).fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.callout)
                }
            }
            if let confidence = recommendation.confidence {
                Text(confidence.note)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Spacer()
                Button("Show Breakdown", action: onShowBreakdown)
                    .accessibilityIdentifier("pricing.suggestion.breakdown")
                if isApplied {
                    Button("Applied") {}
                        .disabled(true)
                } else {
                    Button("Apply", action: onApply)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .accessibilityIdentifier("pricing.suggestion.apply")
                }
            }
            .buttonBorderShape(.capsule)
        }
        .padding(Spacing.large)
        .frame(width: 360)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.suggestionPopover")
    }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            FlagTile(regionCode: row.territory.alpha2)
            Text(row.territory.name).font(.headline)
            Spacer()
            if let confidence = recommendation.confidence {
                Pill(text: confidence.title)
            }
        }
    }

    private func priceCard(title: String, price: Decimal, feelsLike: String, ratio: String, delta: Int?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
            HStack(spacing: Spacing.xSmall) {
                Text(row.currency.format(price))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                if let delta, delta != 0 { DeltaPill(percent: delta) }
            }
            Text("feels like \(feelsLike) · \(ratio) the \(baseName)")
                .font(.caption)
                .foregroundStyle(Palette.label2)
        }
        .padding(Spacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field))
        .accessibilityElement(children: .combine)
    }
}
