//
//  PriceMatrixTable.swift
//  AppLocalizer
//

import SwiftUI

/// The price matrix: one row per territory, sortable, multi-selectable
/// (click, ⌘-click, ⇧-click). Every column is declared; the Columns preset
/// shows a few, and the header's context menu can show or hide any.
struct PriceMatrixTable: View {
    let viewModel: PricingViewModel
    @Bindable var matrix: PriceMatrixModel

    @State private var columns: TableColumnCustomization<PricingRow>

    init(viewModel: PricingViewModel, matrix: PriceMatrixModel) {
        self.viewModel = viewModel
        self.matrix = matrix
        // The preset's columns from the first layout: hiding columns after
        // the table sized all of them leaves the rest too wide.
        _columns = State(initialValue: Self.customization(for: viewModel.resolvedPreset))
    }

    var body: some View {
        Table(matrix.visibleRows, selection: $matrix.selection, sortOrder: $matrix.sortOrder, columnCustomization: $columns) {
            Group {
                TableColumn("Territory", value: \PricingRow.territory.name) { row in territoryCell(row) }
                    .width(min: 150, ideal: 170)
                    .customizationID(PriceColumn.territory.customizationID)
                    .disabledCustomizationBehavior(.visibility)
                TableColumn("Region", value: \PricingRow.regionTitle) { row in secondaryText(row.regionTitle) }
                    .width(min: 80, ideal: 110)
                    .customizationID(PriceColumn.region.customizationID)
                TableColumn("Currency", value: \PricingRow.territory.currencyCode) { row in
                    Text(row.territory.currencyCode).font(.caption.monospaced()).foregroundStyle(Palette.label2)
                }
                .width(min: 56, ideal: 64)
                .customizationID(PriceColumn.currency.customizationID)
                TableColumn(currentTitle, value: \PricingRow.currentSortKey) { row in currentCell(row) }
                    .width(min: 80, ideal: 100)
                    .alignment(.trailing)
                    .customizationID(PriceColumn.current.customizationID)
                TableColumn("Proceeds", value: \PricingRow.proceedsSortKey) { row in moneyText(row.currency.format(row.current.proceeds)) }
                    .width(min: 70, ideal: 90)
                    .alignment(.trailing)
                    .customizationID(PriceColumn.proceeds.customizationID)
                TableColumn("USD equiv.", value: \PricingRow.currentSortKey) { row in dollarsCell(row) }
                    .width(min: 70, ideal: 90)
                    .alignment(.trailing)
                    .customizationID(PriceColumn.dollars.customizationID)
                TableColumn("Equalized", value: \PricingRow.equalizedSortKey) { row in
                    moneyText(row.currency.format(row.equalized)).foregroundStyle(Palette.label2)
                }
                .width(min: 80, ideal: 96)
                .alignment(.trailing)
                .customizationID(PriceColumn.equalized.customizationID)
                TableColumn("Feels like", value: \PricingRow.feelsLikeSortKey) { row in feelsLikeCell(row) }
                    .width(min: 70, ideal: 80)
                    .alignment(.trailing)
                    .customizationID(PriceColumn.feelsLike.customizationID)
            }
            Group {
                TableColumn("Suggested", value: \PricingRow.suggestedSortKey) { row in
                    SuggestedPriceCell(row: row, matrix: matrix, baseName: baseName)
                }
                .width(min: 90, ideal: 110)
                .customizationID(PriceColumn.suggested.customizationID)
                TableColumn("Reason", value: \PricingRow.reasonSortKey) { row in reasonCell(row) }
                    .width(min: 120, ideal: 220)
                    .customizationID(PriceColumn.reason.customizationID)
                TableColumn("Factor", value: \PricingRow.factorSortKey) { row in factorCell(row) }
                    .width(min: 50, ideal: 64)
                    .alignment(.trailing)
                    .customizationID(PriceColumn.factor.customizationID)
                TableColumn("Source", value: \PricingRow.sourceSortKey) { row in sourceCell(row) }
                    .width(min: 90, ideal: 110)
                    .customizationID(PriceColumn.source.customizationID)
                TableColumn("Proposed", value: \PricingRow.proposedSortKey) { row in
                    ProposedPriceCell(row: row, viewModel: viewModel, matrix: matrix)
                }
                .width(min: 120, ideal: 150)
                .alignment(.trailing)
                .customizationID(PriceColumn.proposed.customizationID)
                TableColumn("Change", value: \PricingRow.changeSortKey) { row in changeCell(row) }
                    .width(min: 56, ideal: 70)
                    .customizationID(PriceColumn.change.customizationID)
                TableColumn("Status", value: \PricingRow.statusSortKey) { row in statusCell(row) }
                    .width(min: 90, ideal: 120)
                    .customizationID(PriceColumn.status.customizationID)
                TableColumn("Pricing", value: \PricingRow.pricingText) { row in secondaryText(row.pricingText) }
                    .width(min: 70, ideal: 90)
                    .customizationID(PriceColumn.pricing.customizationID)
            }
        }
        .contextMenu(forSelectionType: PricingRow.ID.self) { ids in
            if !matrix.isReadOnly {
                BulkActionsMenu(viewModel: viewModel, matrix: matrix, ids: Array(ids))
            }
        } primaryAction: { ids in
            guard ids.count == 1, let id = ids.first, let row = matrix.row(id: id), !matrix.isReadOnly else { return }
            matrix.popover = matrix.showsStepper(row) || row.recommendation == nil ? .breakdown(id) : .suggestion(id)
        }
        .onAppear(perform: applyPreset)
        .onChange(of: viewModel.resolvedPreset) { applyPreset() }
        .accessibilityIdentifier("pricing.matrix")
    }

    private var currentTitle: String {
        viewModel.resolvedPreset == .pricesAndProceeds ? String(localized: "Price") : String(localized: "Current")
    }

    var baseName: String { matrix.baseRow?.territory.referenceName ?? "US" }

    /// Shows the preset's columns and hides the rest.
    private func applyPreset() {
        let visible = Set(viewModel.resolvedPreset.columns)
        for column in PriceColumn.allCases {
            columns[visibility: column.customizationID] = visible.contains(column) ? .visible : .hidden
        }
    }

    private static func customization(for preset: PriceColumnPreset) -> TableColumnCustomization<PricingRow> {
        var customization = TableColumnCustomization<PricingRow>()
        let visible = Set(preset.columns)
        for column in PriceColumn.allCases {
            customization[visibility: column.customizationID] = visible.contains(column) ? .visible : .hidden
        }
        return customization
    }
}
