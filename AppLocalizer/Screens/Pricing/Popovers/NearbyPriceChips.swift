//
//  NearbyPriceChips.swift
//  AppLocalizer
//

import SwiftUI

/// The price points around the proposed one; clicking one sets it by hand.
struct NearbyPriceChips: View {
    let territoryID: String
    let points: [PricePoint]
    let current: Decimal
    let currency: CurrencyFormat
    let onPick: (Decimal) -> Void

    var body: some View {
        FlowLayout(spacing: Spacing.xSmall) {
            ForEach(points, id: \.customerPrice) { point in
                let isCurrent = !PricingRow.differs(point.customerPrice, current)
                Button {
                    onPick(point.customerPrice)
                } label: {
                    Text(currency.format(point.customerPrice))
                        .font(.callout)
                        .monospacedDigit()
                        .padding(.horizontal, Spacing.small)
                        .padding(.vertical, Spacing.xxSmall)
                        .foregroundStyle(isCurrent ? Palette.accentText : Palette.label)
                        .background(isCurrent ? Palette.accentTint : Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field))
                        .overlay {
                            if isCurrent {
                                RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Palette.accentText, lineWidth: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                .accessibilityHint(String(localized: "Sets this price by hand"))
                .accessibilityIdentifier("pricing.nearby.\(territoryID).\(NSDecimalNumber(decimal: point.customerPrice).stringValue)")
            }
        }
    }
}

#Preview {
    NearbyPriceChips(
        territoryID: "BRA",
        points: [98.9, 99.9, 104.9, 109.9, 114.9].map { PricePoint(customerPrice: Decimal(exactly: $0), proceeds: 0) },
        current: Decimal(exactly: 109.9),
        currency: .forCurrency("BRL"),
        onPick: { _ in }
    )
    .frame(width: 380)
    .padding()
}
