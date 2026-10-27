//
//  PricingModeMenu.swift
//  AppLocalizer
//

import SwiftUI

/// The section bar's pricing mode menu, for this app only. The default for
/// new apps lives in Settings.
struct PricingModeMenu: View {
    let viewModel: PricingViewModel

    var body: some View {
        Menu {
            Section(String(localized: "Pricing Mode for \(viewModel.app.name)")) {
                ForEach(PricingMode.allCases) { mode in
                    Toggle(isOn: Binding(
                        get: { viewModel.mode == mode },
                        set: { _ in Task { await viewModel.setMode(mode) } }
                    )) {
                        Text(mode.title)
                        Text(Self.description(of: mode))
                    }
                }
            }
            Divider()
            Text("The default for new apps is in Settings → Pricing.")
        } label: {
            Label(viewModel.mode.title, systemImage: viewModel.mode.systemImage)
        }
        .fixedSize()
        .help("Pricing mode for this app")
        .accessibilityLabel(String(localized: "Pricing mode"))
        .accessibilityValue(viewModel.mode.title)
        .accessibilityIdentifier("pricing.modeMenu")
    }

    static func description(of mode: PricingMode) -> String {
        switch mode {
        case .keepPrices: String(localized: "Translate only. AppLocalizer never proposes a price change.")
        case .showSuggestions: String(localized: "A suggested price per territory. Nothing changes until you apply.")
        case .applyRecommended: String(localized: "Fill every territory with its suggestion, then review before pushing.")
        }
    }
}
