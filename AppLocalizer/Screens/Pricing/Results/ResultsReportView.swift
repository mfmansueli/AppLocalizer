//
//  ResultsReportView.swift
//  AppLocalizer
//

import SwiftUI

/// Four weeks after a push: the 28 days before and after, as totals and per
/// territory, with Restore where it got worse.
struct ResultsReportView: View {
    let model: PriceResultsModel
    let changedOn: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Before and after \(PricingText.date(changedOn))")
                    .font(.title3.weight(.semibold))
                Text("""
                28 days before each change compared with the 28 days after. App Store Connect can’t run price tests, \
                so this shows what changed, not why.
                """)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .lineLimit(2)
            }
            if let summary = model.summary {
                cards(summary)
            }
            table
                .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                        .strokeBorder(Palette.separator, lineWidth: 0.5)
                }
            Text(footnote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .lineLimit(4)
                .frame(maxWidth: 760, alignment: .leading)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        // No minimum from the texts: a width-dependent one makes the split
        // view resize in a loop.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.results.report")
    }

    private func cards(_ summary: ResultsSummary) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            card(
                title: String(localized: "Subscription starts"),
                value: "\(PricingText.grouped(summary.startsBefore)) → \(PricingText.grouped(summary.startsAfter))",
                caption: String(localized: "\(summary.startsChange.percentText) in territories with enough data")
            )
            card(
                title: String(localized: "Proceeds, 28 days"),
                value: "\(CurrencyFormat.usd.formatWhole(summary.proceedsBefore)) → \(CurrencyFormat.usd.formatWhole(summary.proceedsAfter))",
                caption: String(localized: "\(summary.proceedsChange.percentText) · after Apple’s commission and taxes")
            )
            card(
                title: String(localized: "Territories"),
                value: String(localized: "\(summary.countedCount) with enough data"),
                caption: summary.breakdownText
            )
        }
        .frame(height: 96)
    }

    private func card(title: String, value: String, caption: String) -> some View {
        Card(padding: Spacing.medium) {
            Text(title)
                .font(.callout)
                .foregroundStyle(Palette.label2)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(maxHeight: .infinity)
    }

    private var table: some View {
        Table(model.results) {
            TableColumn("Territory") { result in
                HStack(spacing: Spacing.small) {
                    FlagTile(regionCode: result.territory.alpha2)
                    Text(result.territory.name).lineLimit(1)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("pricing.results.row.\(result.id)")
            }
            .width(min: 110, ideal: 125)
            TableColumn("Price") { result in priceCell(result) }
                .width(min: 150, ideal: 190)
            TableColumn("Starts") { result in
                arrowText("\(PricingText.grouped(result.before.starts))", "\(PricingText.grouped(result.after.starts))")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 56, ideal: 65)
            TableColumn("Page view → start") { result in
                arrowText(result.before.conversionText, result.after.conversionText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 96, ideal: 105)
            TableColumn("Proceeds") { result in
                arrowText(CurrencyFormat.usd.formatWhole(result.before.proceeds), CurrencyFormat.usd.formatWhole(result.after.proceeds))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 90, ideal: 115)
            TableColumn("Result") { result in
                Pill(text: result.verdict.title, style: result.verdict == .worse ? .warning : .neutral)
                    .help(result.verdict.title)
            }
            .width(min: 80, ideal: 100)
            TableColumn("") { result in restoreCell(result) }
                .width(min: 76, ideal: 80)
        }
        .accessibilityIdentifier("pricing.results.table")
    }

    private func priceCell(_ result: PriceChangeResult) -> some View {
        let currency = CurrencyFormat.forCurrency(result.territory.currencyCode)
        return HStack(spacing: Spacing.xxSmall) {
            Text(currency.format(result.oldPrice))
                .foregroundStyle(Palette.label2)
            Image(systemName: "arrow.right")
                .imageScale(.small)
                .accessibilityHidden(true)
            Text(currency.format(result.newPrice))
                .fontWeight(.semibold)
        }
        .monospacedDigit()
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }

    private func arrowText(_ before: String, _ after: String) -> some View {
        Text(verbatim: "\(before) → \(after)")
            .monospacedDigit()
            .lineLimit(1)
            .accessibilityLabel(String(localized: "\(before) before, \(after) after"))
    }

    @ViewBuilder
    private func restoreCell(_ result: PriceChangeResult) -> some View {
        if model.isRestoreQueued(result.id) {
            Pill(text: String(localized: "Queued"), systemImage: "checkmark", style: .accent)
                .help(String(localized: "The old price waits in Review & Push."))
                .accessibilityIdentifier("pricing.results.restored.\(result.id)")
        } else if model.canRestore(result) {
            Button {
                model.restore(result.id)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
            .help(String(localized: "Queue the old price for review in Review & Push"))
            .accessibilityLabel(String(localized: "Restore the old price in \(result.territory.name)"))
            .accessibilityIdentifier("pricing.results.restore.\(result.id)")
        }
    }

    private var footnote: String {
        let caveat = String(localized: """
        Seasonality, featuring and your own marketing also move these numbers. “Better” means more starts and at least \
        the same proceeds; “Worse” offers to restore the old price, which goes through Review & Push like any other change.
        """)
        guard let count = model.summary?.tooLittleDataCount, count > 0 else { return caveat }
        let hidden = count == 1
            ? String(localized: "1 more territory had too few sales to tell.")
            : String(localized: "\(count) more territories had too few sales to tell.")
        return hidden + " " + caveat
    }
}
