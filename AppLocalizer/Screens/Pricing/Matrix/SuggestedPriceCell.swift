//
//  SuggestedPriceCell.swift
//  AppLocalizer
//

import SwiftUI

/// The Suggested cell: the suggested price and its confidence; clicking it
/// explains why in a popover.
struct SuggestedPriceCell: View {
    let row: PricingRow
    let matrix: PriceMatrixModel
    let baseName: String

    var body: some View {
        if let recommendation = row.recommendation, !recommendation.isUnchanged, !row.isBase {
            Button {
                matrix.popover = .suggestion(row.id)
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    Text(row.currency.format(recommendation.price.customerPrice))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    if let confidence = recommendation.confidence {
                        ConfidenceBars(confidence: confidence)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Suggested \(row.currency.format(recommendation.price.customerPrice))"))
            .accessibilityValue(recommendation.confidence?.title ?? "")
            .accessibilityHint(String(localized: "Explains the suggestion"))
            .accessibilityIdentifier("pricing.suggested.\(row.id)")
            .popover(isPresented: isPresented, arrowEdge: .bottom) {
                SuggestionPopover(
                    row: row,
                    recommendation: recommendation,
                    baseName: baseName,
                    isApplied: row.queued.map { !PricingRow.differs($0.price, recommendation.price.customerPrice) } ?? false,
                    onShowBreakdown: { matrix.popover = .breakdown(row.id) },
                    onApply: { Task { await matrix.applySuggestion(to: [row.id]) } }
                )
            }
        } else {
            Text(verbatim: "—")
                .foregroundStyle(Palette.label3)
                .accessibilityLabel(String(localized: "No suggestion"))
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { matrix.popover == .suggestion(row.id) },
            set: { isPresented in
                if !isPresented, matrix.popover == .suggestion(row.id) { matrix.popover = nil }
            }
        )
    }
}
