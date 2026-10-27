//
//  ExcludedSection.swift
//  AppLocalizer
//

import SwiftUI

/// Territories the index leaves alone: they stay at Apple's equalized price.
struct ExcludedSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        let excluded = model.territories.territories.filter { model.strategy.isExcluded($0.id) }
        InspectorSection(
            .excluded,
            in: model,
            trailing: { addMenu },
            content: {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    if !excluded.isEmpty {
                        FlowLayout(spacing: Spacing.xSmall) {
                            ForEach(excluded) { territory in
                                chip(territory)
                            }
                        }
                    }
                    Text("""
                    Excluded territories stay at Apple’s equalized price. Useful for Japan, where a weak yen makes the \
                    Big Mac Index suggest a deep cut in a market that already pays well for apps.
                    """)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        )
    }

    private var addMenu: some View {
        Menu("Add…") {
            ForEach(TerritoryRegion.allCases, id: \.self) { region in
                Menu(region.title) {
                    ForEach(viewModel.strategy.territories.territories(in: region)) { territory in
                        Button(territory.name) { viewModel.toggleExclusion(of: territory.id) }
                            .disabled(viewModel.strategy.strategy.isExcluded(territory.id))
                    }
                }
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel(String(localized: "Exclude a territory"))
        .accessibilityIdentifier("pricing.excluded.add")
    }

    private func chip(_ territory: Territory) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            FlagTile(regionCode: territory.alpha2, size: 12)
            Text(territory.name).font(.callout)
            Button {
                viewModel.toggleExclusion(of: territory.id)
            } label: {
                Image(systemName: "xmark").font(.caption2.weight(.bold))
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "Include \(territory.name) in the index again"))
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, 3)
        .background(Palette.fill2, in: Capsule())
        .accessibilityElement(children: .contain)
    }
}
