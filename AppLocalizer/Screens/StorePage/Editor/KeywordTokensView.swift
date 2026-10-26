//
//  KeywordTokensView.swift
//  AppLocalizer
//

import SwiftUI

/// Under the keywords field: each keyword as a token (duplicates yellow,
/// words already in the name or subtitle struck through), what's wasted,
/// "Optimize · saves n bytes", and a legend.
struct KeywordTokensView: View {
    let analysis: KeywordAnalysis
    let isEditable: Bool
    let onRemove: (Int) -> Void
    let onOptimize: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            FlowLayout(spacing: 5) {
                ForEach(analysis.tokens) { token in
                    KeywordTokenChip(token: token, isEditable: isEditable) {
                        onRemove(token.index)
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Keywords"))
            .accessibilityIdentifier("storePage.keywordTokens")
            HStack(spacing: Spacing.small) {
                Text(analysis.summary)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("storePage.keywordSummary")
                Spacer(minLength: Spacing.small)
                if isEditable, analysis.canOptimize {
                    Button(action: onOptimize) {
                        Label(analysis.optimizeTitle, systemImage: "sparkles")
                    }
                    .controlSize(.small)
                    .accessibilityIdentifier("storePage.optimizeKeywords")
                }
            }
            legend
        }
    }

    private var legend: some View {
        HStack(spacing: Spacing.medium) {
            HStack(spacing: Spacing.xxSmall) {
                KeywordTokenChip.sample(state: .duplicate)
                Text("duplicate")
            }
            HStack(spacing: Spacing.xxSmall) {
                KeywordTokenChip.sample(state: .inNameOrSubtitle)
                Text("already in the name or subtitle")
            }
            Text("Commas only, no spaces: each space costs a byte.")
        }
        .font(.caption2)
        .foregroundStyle(Palette.label2)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
