//
//  TerritoryTab.swift
//  AppLocalizer
//

import SwiftUI

/// The inspector's Territory tab for the selected row: its breakdown under
/// the strategy, the sources compared, and a switch to exclude it.
struct TerritoryTab: View {
    let viewModel: PricingViewModel
    let matrix: PriceMatrixModel?

    var body: some View {
        if let matrix, let row = inspectedRow(in: matrix) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.small) {
                    FlagTile(regionCode: row.territory.alpha2)
                    Text(row.territory.name).font(.headline)
                    Spacer()
                    Text(verbatim: "\(row.territory.currencyCode) · \(row.territory.region.title)")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .padding(Spacing.large)
                .overlay(alignment: .bottom) { Divider() }
                section(String(localized: "Price Breakdown")) {
                    PriceBreakdownSteps(summary: row.calculation.summary, steps: row.calculation.steps)
                }
                section(String(localized: "Compare Sources")) {
                    CompareSourcesView(
                        territoryID: row.id,
                        comparisons: matrix.comparison(for: row),
                        currency: row.currency,
                        canEdit: !matrix.isReadOnly
                    ) { price in
                        Task { await matrix.setPrice(row.id, to: price) }
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Toggle(isOn: Binding(
                        get: { viewModel.strategy.strategy.isExcluded(row.id) },
                        set: { _ in viewModel.toggleExclusion(of: row.id) }
                    )) {
                        Text("Exclude \(row.territory.name) from the index").font(.callout)
                    }
                    .toggleStyle(.switch)
                    .disabled(row.isBase)
                    .accessibilityIdentifier("pricing.territory.exclude")
                    Text("Keeps Apple’s equalized price here.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                }
                .padding(Spacing.large)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("pricing.territoryTab")
        } else {
            ContentUnavailableView(
                "No Territory Selected",
                systemImage: "globe",
                description: Text("Select a territory in the table to see its breakdown and compare sources.")
            )
            .padding(.top, Spacing.xxxLarge)
        }
    }

    private func inspectedRow(in matrix: PriceMatrixModel) -> PricingRow? {
        if let popover = matrix.popover, let row = matrix.row(id: popover.rowID) { return row }
        return matrix.selectedRows.first
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Palette.label2)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Divider() }
    }
}
