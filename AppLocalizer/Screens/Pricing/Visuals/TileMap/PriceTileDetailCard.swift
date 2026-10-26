//
//  PriceTileDetailCard.swift
//  AppLocalizer
//

import SwiftUI

/// What hovering a tile shows: today's price and the proposed one, the US
/// dollar equivalent against the base price, and what it feels like with
/// the factor behind it.
struct PriceTileDetailCard: View {
    let detail: PriceTileMap.Detail

    static let width: CGFloat = 230

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(detail.title)
                .font(.headline)
            HStack(spacing: Spacing.xxSmall) {
                Text(detail.today)
                if let proposed = detail.proposed {
                    Text(verbatim: "→").foregroundStyle(Palette.label2)
                    Text(proposed).fontWeight(.semibold)
                }
            }
            .font(.callout)
            .monospacedDigit()
            Group {
                Text(detail.dollars)
                Text(detail.feelsLike)
            }
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .monospacedDigit()
        }
        .lineLimit(1)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .frame(width: Self.width, alignment: .leading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.banner, style: .continuous)
                .strokeBorder(Palette.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("pricing.tileDetail")
    }
}
