//
//  PricingPriceBar.swift
//  AppLocalizer
//

import SwiftUI

/// How a product's prices are set, as one bar: equalized, custom, suggested
/// (purple) and not pushed (blue), in proportion.
struct PricingPriceBar: View {
    let card: PricingProductCard

    private var parts: [(count: Int, color: Color)] {
        [
            (card.equalizedCount, Palette.fill3),
            (card.customCount, Palette.label3),
            (card.suggestedCount, Palette.suggestionBadge),
            (card.queuedCount, Palette.accent),
        ].filter { $0.count > 0 }
    }

    var body: some View {
        GeometryReader { proxy in
            let total = max(1, card.territoryCount)
            HStack(spacing: 1) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    Rectangle()
                        .fill(part.color)
                        .frame(width: max(2, (proxy.size.width - CGFloat(parts.count - 1)) * CGFloat(part.count) / CGFloat(total)))
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .accessibilityElement()
        .accessibilityLabel(Text(card.legend))
    }
}
