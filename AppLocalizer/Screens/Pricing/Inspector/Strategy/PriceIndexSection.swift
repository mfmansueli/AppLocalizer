//
//  PriceIndexSection.swift
//  AppLocalizer
//

import SwiftUI

/// The price index the strategy reads, one card per source. Picking one
/// switches the method to Price index.
struct PriceIndexSection: View {
    let viewModel: PricingViewModel
    let onImport: () -> Void

    var body: some View {
        let strategy = viewModel.strategy
        InspectorSection(.priceIndex, in: strategy) {
            VStack(spacing: Spacing.small) {
                ForEach(PriceIndexSource.allCases) { source in
                    PriceIndexCard(
                        source: source,
                        index: strategy.index(source),
                        territoryCount: strategy.territories.count,
                        isSelected: strategy.strategy.method == .priceIndex && strategy.strategy.indexSource == source,
                        now: .now,
                        onSelect: {
                            viewModel.editStrategy { strategy in
                                strategy.method = .priceIndex
                                strategy.indexSource = source
                            }
                        },
                        onImport: onImport
                    )
                }
            }
        }
    }
}
