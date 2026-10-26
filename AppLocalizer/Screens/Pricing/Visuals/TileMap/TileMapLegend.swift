//
//  TileMapLegend.swift
//  AppLocalizer
//

import SwiftUI

/// The tile map's color key: teal through neutral to orange for the
/// diverging metrics, light to full accent for the others, with the ends
/// labeled.
struct TileMapLegend: View {
    let metric: TileMapMetric
    let lowLabel: String
    let highLabel: String

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(lowLabel)
            Capsule()
                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                .frame(width: 160, height: 8)
                .accessibilityHidden(true)
            Text(highLabel)
        }
        .font(.caption)
        .foregroundStyle(Palette.label2)
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Color scale from \(lowLabel) to \(highLabel)"))
    }

    private var colors: [Color] {
        metric.isDiverging
            ? [Palette.decreaseMark, Palette.fill2, Palette.increaseMark]
            : [Palette.content.mix(with: Palette.accent, by: 0.1), Palette.accent]
    }
}
