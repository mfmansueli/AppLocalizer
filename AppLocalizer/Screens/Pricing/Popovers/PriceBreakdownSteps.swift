//
//  PriceBreakdownSteps.swift
//  AppLocalizer
//

import SwiftUI

/// The formula in one line, then one numbered line per step, as in the
/// breakdown popover and the inspector's Territory tab.
struct PriceBreakdownSteps: View {
    let summary: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(summary)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field))
                .overlay { RoundedRectangle(cornerRadius: Radius.field).strokeBorder(Palette.separator, lineWidth: 0.5) }
                .accessibilityLabel(String(localized: "Formula: \(summary)"))
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                        Text(index + 1, format: .number)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.label3)
                            .frame(width: 12, alignment: .trailing)
                        Text(step)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

#Preview {
    PriceBreakdownSteps(
        summary: "R$ 219,90 equalized × 0.5 = R$ 109,95 → above floor → R$ 109,90",
        steps: ["R$ 219,90 — Apple’s equalized price for $39.99", "× 0.50 (World Bank 2024) = R$ 109,95", "Nearest price point → R$ 109,90"]
    )
    .frame(width: 380)
    .padding()
}
