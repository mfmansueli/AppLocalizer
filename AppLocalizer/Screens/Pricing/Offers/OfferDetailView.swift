//
//  OfferDetailView.swift
//  AppLocalizer
//

import SwiftUI

/// One offer: who gets it and how it's paid, then its price in the
/// most-viewed territories, derived from each subscription price.
struct OfferDetailView: View {
    let offer: SubscriptionOffer
    /// Every territory, most-viewed first.
    let prices: [OfferPrice]

    /// The table shows this many; every territory is pushed.
    private let shownCount = 9

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                    Text(offer.name)
                        .font(.title3.weight(.semibold))
                    Pill(text: offer.kind.title)
                }
                facts
                table
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.offerDetail")
    }

    private var facts: some View {
        box {
            fact(String(localized: "Who can get it"), offer.eligibility, isFirst: true)
            fact(String(localized: "Payment"), offer.paymentMode.title)
            fact(String(localized: "Duration"), offer.duration)
            fact(String(localized: "Offer price"), offer.rule)
        }
    }

    private func fact(_ title: String, _ value: String, isFirst: Bool = false) -> some View {
        VStack(spacing: 0) {
            if !isFirst { Divider() }
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                Text(title)
                Spacer(minLength: Spacing.medium)
                Text(value)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: 40)
            .accessibilityElement(children: .combine)
        }
    }

    private var table: some View {
        box {
            Grid(alignment: .trailing, horizontalSpacing: Spacing.medium, verticalSpacing: 0) {
                GridRow {
                    header(String(localized: "Territory")).gridColumnAlignment(.leading)
                    header(String(localized: "Subscription"))
                    header(String(localized: "Offer price"))
                    header(String(localized: "You receive"))
                }
                ForEach(prices.prefix(shownCount)) { price in
                    Divider()
                    row(price)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .monospacedDigit()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.offers.table")
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.callout.weight(.medium))
            .foregroundStyle(Palette.label2)
            .frame(minHeight: 30)
    }

    /// Modifiers go on the cells: a modified `GridRow` stops being a row.
    private func row(_ price: OfferPrice) -> some View {
        let currency = CurrencyFormat.forCurrency(price.territory.currencyCode)
        let offerText = price.offerPrice.map { currency.format($0.customerPrice) } ?? String(localized: "Free")
        let receiveText = price.proceeds.map { currency.format($0) } ?? "—"
        return GridRow {
            HStack(spacing: Spacing.small) {
                FlagTile(regionCode: price.territory.alpha2)
                Text(price.territory.name).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(localized: """
            \(price.territory.name): subscription \(currency.format(price.subscriptionPrice)), offer \(offerText), \
            you receive \(receiveText)
            """))
            .accessibilityIdentifier("pricing.offers.row.\(price.id)")
            Text(currency.format(price.subscriptionPrice))
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text(offerText)
                .fontWeight(.semibold)
                .accessibilityHidden(true)
            Text(receiveText)
                .accessibilityHidden(true)
        }
    }

    private func box(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(Palette.separator, lineWidth: 0.5)
            }
    }

    private var footnote: String {
        String(localized: """
        Offer prices follow each territory’s subscription price and snap to its price points, so when a territory’s \
        price drops its offer drops too. The \(min(shownCount, prices.count)) territories with the most page views are \
        shown here; all \(prices.count) are pushed.
        """)
    }
}
