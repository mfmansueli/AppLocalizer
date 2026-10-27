//
//  BulkActionsMenu.swift
//  AppLocalizer
//

import SwiftUI

/// What can be done to the selected territories at once, shared by the
/// bottom bar's More menu and the rows' context menu.
struct BulkActionsMenu: View {
    let viewModel: PricingViewModel
    let matrix: PriceMatrixModel
    let ids: [PricingRow.ID]

    var body: some View {
        Button("Apply Suggestion") { run { await matrix.applySuggestion(to: ids) } }
            .disabled(ids.isEmpty)
        Divider()
        Group {
            Button("Multiply by 0.9") { run { await matrix.multiply(ids, by: Decimal(9) / 10) } }
            Button("Multiply by 0.8") { run { await matrix.multiply(ids, by: Decimal(8) / 10) } }
            Button("Multiply by 1.1") { run { await matrix.multiply(ids, by: Decimal(11) / 10) } }
            Button("Set to Feel Like \(matrix.product.basePriceText ?? "")") { run { await matrix.feelLikeBase(ids) } }
            Button("Reset to Equalized") { run { await matrix.resetToEqualized(ids) } }
        }
        .disabled(ids.isEmpty)
        if !viewModel.siblings.isEmpty {
            Divider()
            ForEach(viewModel.siblings) { sibling in
                if let ratio = viewModel.ratioText(from: sibling) {
                    Button("Copy from \(sibling.period?.shortTitle ?? sibling.name) × \(ratio)") {
                        run { await viewModel.copy(from: sibling, to: ids) }
                    }
                    .disabled(ids.isEmpty)
                }
            }
            Button("Apply Strategy to Whole Group…") { viewModel.isGroupConfirmationPresented = true }
        }
        Divider()
        Button("Select All Visible") { matrix.selectAllVisible() }
        Button("Clear Selection") { matrix.clearSelection() }
            .disabled(matrix.selection.isEmpty)
    }

    private func run(_ action: @escaping @MainActor () async -> Void) {
        Task { await action() }
    }
}
