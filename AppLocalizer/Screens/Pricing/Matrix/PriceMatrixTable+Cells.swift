//
//  PriceMatrixTable+Cells.swift
//  AppLocalizer
//

import SwiftUI

/// The matrix's plain cells. Each keeps its own VoiceOver label for column
/// navigation; the territory cell reads the whole row.
extension PriceMatrixTable {
    func territoryCell(_ row: PricingRow) -> some View {
        HStack(spacing: Spacing.small) {
            FlagTile(regionCode: row.territory.alpha2)
            Text(row.territory.name)
                .lineLimit(1)
                .truncationMode(.tail)
            if row.isBase {
                Pill(text: String(localized: "Base"))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowLabel(row))
        .accessibilityIdentifier("pricing.row.\(row.id)")
    }

    func currentCell(_ row: PricingRow) -> some View {
        moneyText(row.currency.format(row.current.customerPrice))
            .fontWeight(viewModel.resolvedPreset == .pricesAndProceeds ? .semibold : .regular)
    }

    func dollarsCell(_ row: PricingRow) -> some View {
        let text = row.dollars.map { CurrencyFormat.usd.format($0) } ?? "—"
        return moneyText(text)
            .foregroundStyle(Palette.label2)
            .help(String(localized: "Approximate, from bundled exchange rates"))
            .accessibilityLabel(String(localized: "About \(text)"))
    }

    @ViewBuilder
    func feelsLikeCell(_ row: PricingRow) -> some View {
        if let recommendation = row.recommendation {
            HStack(spacing: Spacing.xxSmall) {
                Text(recommendation.feelsLikeText).monospacedDigit()
                Text(recommendation.ratioText)
                    .font(.caption2)
                    .foregroundStyle(Palette.label3)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        } else {
            secondaryText("—")
        }
    }

    func reasonCell(_ row: PricingRow) -> some View {
        Text(row.recommendation?.reason ?? "")
            .foregroundStyle(Palette.label2)
            .lineLimit(1)
            .truncationMode(.tail)
            .help(row.recommendation?.reason ?? "")
    }

    func factorCell(_ row: PricingRow) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            if let tier = row.calculation.tierLabel {
                Pill(text: tier, style: .outline)
            }
            Text(row.calculation.factor.fixed(2)).monospacedDigit()
        }
    }

    func sourceCell(_ row: PricingRow) -> some View {
        Pill(text: row.calculation.provenance.badge, style: row.calculation.isExcluded ? .outline : .neutral)
            .help(row.isFallback ? String(localized: "Fallback: \(row.calculation.provenance.label)") : row.calculation.provenance.label)
    }

    @ViewBuilder
    func changeCell(_ row: PricingRow) -> some View {
        if let change = row.change {
            DeltaPill(percent: change.percent)
        } else if row.calculation.isExcluded, !matrix.isReadOnly {
            Pill(text: String(localized: "Excluded"), style: .outline)
        }
    }

    @ViewBuilder
    func statusCell(_ row: PricingRow) -> some View {
        let status = row.status
        if let systemImage = status.systemImage {
            Label(status.title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(status == .unchanged ? Palette.label3 : Palette.label)
                .lineLimit(1)
        } else {
            Text(status.title)
                .foregroundStyle(Palette.label3)
                .lineLimit(1)
        }
    }

    func secondaryText(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(Palette.label2)
            .lineLimit(1)
    }

    func moneyText(_ text: String) -> some View {
        Text(text)
            .monospacedDigit()
            .lineLimit(1)
    }

    /// “Brazil, current R$ 219,90, proposed R$ 109,90, down 50 percent,
    /// recommended, medium confidence”.
    func rowLabel(_ row: PricingRow) -> String {
        var parts = [row.territory.name, String(localized: "current \(row.currency.format(row.current.customerPrice))")]
        if let change = row.change {
            parts.append(String(localized: "proposed \(row.currency.format(change.new))"))
            parts.append(change.direction == .increase
                ? String(localized: "up \(abs(change.percent)) percent")
                : String(localized: "down \(abs(change.percent)) percent"))
            parts.append(row.status.title.lowercased())
        } else if let recommendation = row.recommendation, !recommendation.isUnchanged, !row.isBase {
            parts.append(String(localized: "suggested \(row.currency.format(recommendation.price.customerPrice))"))
        }
        if let confidence = row.recommendation?.confidence { parts.append(confidence.title.lowercased()) }
        return parts.joined(separator: ", ")
    }
}
