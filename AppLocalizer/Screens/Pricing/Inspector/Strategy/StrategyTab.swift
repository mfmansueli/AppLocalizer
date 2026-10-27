//
//  StrategyTab.swift
//  AppLocalizer
//

import SwiftUI

/// The inspector's Strategy tab: every part of the strategy, top to bottom.
struct StrategyTab: View {
    let viewModel: PricingViewModel
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MethodSection(viewModel: viewModel)
            PriceIndexSection(viewModel: viewModel, onImport: onImport)
            FallbackChainSection(viewModel: viewModel)
            if viewModel.strategy.strategy.method == .regionalTiers {
                RegionalTiersSection(viewModel: viewModel)
            }
            LimitsSection(viewModel: viewModel)
            TiersSection(viewModel: viewModel)
            ExcludedSection(viewModel: viewModel)
            RoundingSection(viewModel: viewModel)
            FormulaSection(viewModel: viewModel)
            IndexDataSection(viewModel: viewModel)
        }
    }
}
