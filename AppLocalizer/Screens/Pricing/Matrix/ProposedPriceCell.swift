//
//  ProposedPriceCell.swift
//  AppLocalizer
//

import SwiftUI

/// The Proposed cell: a stepper once the territory has a proposal (or
/// follows the strategy), else Apply for its suggestion. The breakdown
/// popover opens from here.
struct ProposedPriceCell: View {
    let row: PricingRow
    let viewModel: PricingViewModel
    let matrix: PriceMatrixModel

    var body: some View {
        content
            .popover(isPresented: isPresented, arrowEdge: .bottom) {
                BreakdownPopover(
                    row: row,
                    nearby: matrix.nearbyPoints(for: row),
                    isExcluded: viewModel.strategy.strategy.isExcluded(row.id),
                    onPick: { price in Task { await matrix.setPrice(row.id, to: price) } },
                    onBackToSuggestion: { Task { await matrix.backToSuggestion(row.id) } },
                    onResetToEqualized: { Task { await matrix.resetToEqualized([row.id]) } },
                    onToggleExclusion: { viewModel.toggleExclusion(of: row.id) },
                    onDone: { matrix.popover = nil }
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if matrix.showsStepper(row) {
            PricePointStepper(
                territoryID: row.id,
                territoryName: row.territory.name,
                value: row.currency.format(row.shownPrice),
                isDisabled: matrix.isLoadingLadders,
                onStep: { steps in Task { await matrix.step(row.id, by: steps) } },
                onOpenBreakdown: { matrix.popover = .breakdown(row.id) }
            )
        } else if !matrix.isReadOnly, row.hasSuggestion {
            Button("Apply") {
                Task { await matrix.applySuggestion(to: [row.id]) }
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
            .accessibilityLabel(String(localized: "Apply suggestion for \(row.territory.name)"))
            .accessibilityIdentifier("pricing.apply.\(row.id)")
        } else {
            Text(verbatim: "—")
                .foregroundStyle(Palette.label3)
                .accessibilityLabel(String(localized: "No change proposed"))
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { matrix.popover == .breakdown(row.id) },
            set: { isPresented in
                if !isPresented, matrix.popover == .breakdown(row.id) { matrix.popover = nil }
            }
        )
    }
}
