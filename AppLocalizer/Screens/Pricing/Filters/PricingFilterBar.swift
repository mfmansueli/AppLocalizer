//
//  PricingFilterBar.swift
//  AppLocalizer
//

import SwiftUI

/// The row above the matrix: region, the three filters, the custom
/// strategy's chip, search, Table | Map | Histogram and the Columns menu.
/// It wraps onto more lines as the window narrows.
struct PricingFilterBar: View {
    let viewModel: PricingViewModel
    @Bindable var matrix: PriceMatrixModel

    @State private var display = Display.table

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.small) {
                filters
                strategyChip
                Spacer(minLength: Spacing.small)
                search
                displayPicker
                columnsMenu
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(spacing: Spacing.small) {
                    filters
                    Spacer(minLength: Spacing.small)
                    search
                    displayPicker
                }
                HStack(spacing: Spacing.small) {
                    columnsMenu
                    strategyChip
                }
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                FlowLayout(spacing: Spacing.small) {
                    filters
                    strategyChip
                    search
                    displayPicker
                    columnsMenu
                }
            }
        }
        .controlSize(.small)
        .toggleStyle(.button)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
    }

    private enum Display: Hashable {
        case table
        case map
        case histogram
    }

    @ViewBuilder
    private var filters: some View {
        FittingSegmentedPicker(
            label: String(localized: "Region"),
            options: [(TerritoryRegion?.none, String(localized: "All"))] + TerritoryRegion.allCases.map { (Optional($0), $0.title) },
            selection: $matrix.filter.region
        )
        .fixedSize()
        .accessibilityIdentifier("pricing.regionFilter")
        if !matrix.isReadOnly {
            Toggle("Changed only", isOn: $matrix.filter.changedOnly)
                .accessibilityIdentifier("pricing.filter.changed")
            Toggle("Increases only", isOn: $matrix.filter.increasesOnly)
                .accessibilityIdentifier("pricing.filter.increases")
        }
        Toggle("Fallback only", isOn: $matrix.filter.fallbackOnly)
            .accessibilityIdentifier("pricing.filter.fallback")
    }

    @ViewBuilder
    private var strategyChip: some View {
        if viewModel.strategy.strategy.isCustom, !matrix.isReadOnly {
            Pill(text: String(localized: "Custom strategy"), systemImage: "slider.horizontal.3", isProminent: true)
            Button("Back to Recommended") { viewModel.resetStrategy() }
                .buttonStyle(.link)
                .accessibilityIdentifier("pricing.backToRecommended")
        }
    }

    private var search: some View {
        HStack(spacing: Spacing.xxSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.label3)
                .accessibilityHidden(true)
            TextField(String(localized: "Territory or currency"), text: $matrix.filter.searchText)
                .textFieldStyle(.plain)
                .accessibilityLabel(String(localized: "Search territories"))
                .accessibilityIdentifier("pricing.search")
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, 3)
        .frame(width: 160)
        .background(Palette.content, in: Capsule())
        .overlay { Capsule().strokeBorder(Palette.separator2, lineWidth: 0.5) }
    }

    private var displayPicker: some View {
        let later = String(localized: "Arrives in a later update")
        return PricingSegmentedControl(
            label: String(localized: "Display"),
            segments: [
                .init(value: Display.table, systemImage: "tablecells", label: String(localized: "Table")),
                .init(value: .map, systemImage: "map", label: String(localized: "Tile map"), isEnabled: false, help: later),
                .init(value: .histogram, systemImage: "chart.bar", label: String(localized: "Histogram"), isEnabled: false, help: later),
            ],
            selection: $display,
            identifier: "pricing.displayPicker"
        )
        .fixedSize()
    }

    private var columnsMenu: some View {
        @Bindable var viewModel = viewModel
        return Menu {
            Picker("Columns", selection: $viewModel.columnPreset) {
                ForEach(PriceColumnPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.inline)
            Divider()
            Text("Automatic shows suggestions, or index columns while Customize is open.")
        } label: {
            Text("Columns: \(viewModel.columnPreset.title)")
        }
        .fixedSize()
        .accessibilityLabel(String(localized: "Columns"))
        .accessibilityValue(viewModel.columnPreset.title)
        .accessibilityIdentifier("pricing.columns")
    }
}
