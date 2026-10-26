//
//  PricingBottomBar.swift
//  AppLocalizer
//

import SwiftUI

/// The bar under the matrix: counts on the left; the selection's actions,
/// the schedule and Apply Recommended Prices… on the right. Keep my prices
/// shows a read-only summary and one quiet link instead.
struct PricingBottomBar: View {
    let viewModel: PricingViewModel
    let matrix: PriceMatrixModel

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(summary)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(.middle)
                .accessibilityIdentifier("pricing.bottomBar.summary")
            Spacer(minLength: Spacing.medium)
            if viewModel.mode == .keepPrices {
                keepActions
            } else if matrix.isReadOnly {
                Text("In-app purchase prices are read-only here for now.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            } else {
                editActions
            }
        }
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .frame(minHeight: 44)
        .overlay(alignment: .top) { Divider() }
        .accessibilityElement(children: .contain)
    }

    private var summary: String {
        let total = matrix.rows.count
        if matrix.isReadOnly {
            let custom = matrix.customCount
            return String(localized: "\(total) territories · \(custom) custom, \(total - custom) equalized · read-only")
        }
        let visible = matrix.visibleRows.count
        var parts = [String(localized: "\(visible) of \(total) territories")]
        if matrix.showsSuggestions {
            parts.append(String(localized: "\(matrix.heldBackCount) likely held back by price"))
        }
        parts.append(String(localized: "\(matrix.pendingCount) pending"))
        return parts.joined(separator: " · ")
    }

    private var keepActions: some View {
        HStack(spacing: Spacing.small) {
            Text("Prices are kept as they are.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
            Button("Show price suggestions") { viewModel.showPriceSuggestions() }
                .buttonStyle(.link)
                .accessibilityIdentifier("pricing.showSuggestions")
        }
    }

    @ViewBuilder
    private var editActions: some View {
        let ids = matrix.selectedRows.map(\.id)
        if !ids.isEmpty {
            Text("\(ids.count) selected")
                .font(.callout.weight(.semibold))
                .accessibilityIdentifier("pricing.selectionCount")
            Button("Apply Suggestion") { Task { await matrix.applySuggestion(to: ids) } }
                .accessibilityIdentifier("pricing.applySelection")
            Menu("More") {
                BulkActionsMenu(viewModel: viewModel, matrix: matrix, ids: ids)
            }
            .fixedSize()
            .accessibilityIdentifier("pricing.more")
        }
        if matrix.pendingCount > 0 {
            Button {} label: {
                Label("Starts now", systemImage: "calendar")
            }
            .disabled(true)
            .help("Scheduling a later start date isn’t available yet. Prices change as soon as Apple processes them.")
            .accessibilityIdentifier("pricing.schedule")
        }
        if viewModel.mode != .applyRecommended {
            Button("Apply Recommended Prices…") { Task { await viewModel.applyRecommendedPrices() } }
                .buttonStyle(.borderedProminent)
                .disabled(matrix.isLoadingLadders)
                .accessibilityIdentifier("pricing.applyRecommended")
        }
    }
}
