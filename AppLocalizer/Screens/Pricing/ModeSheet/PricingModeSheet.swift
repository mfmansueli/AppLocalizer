//
//  PricingModeSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Asks, the first time Pricing opens for an app, how it should handle
/// prices. The default for new apps (from Settings) is preselected.
struct PricingModeSheet: View {
    let appName: String
    let onContinue: (PricingMode) -> Void
    let onNotNow: () -> Void

    @State private var selection: PricingMode

    init(appName: String, initialMode: PricingMode, onContinue: @escaping (PricingMode) -> Void, onNotNow: @escaping () -> Void) {
        self.appName = appName
        self.onContinue = onContinue
        self.onNotNow = onNotNow
        _selection = State(initialValue: initialMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text("How should AppLocalizer handle prices for \(appName)?")
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("You can switch at any time from the Pricing toolbar. The default for new apps is in Settings → Pricing.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(spacing: Spacing.small) {
                    ForEach(PricingMode.allCases) { mode in
                        PricingModeOption(mode: mode, isSelected: selection == mode) { selection = mode }
                    }
                }
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack {
                Spacer()
                Button("Not Now", action: onNotNow)
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("pricing.modeSheet.notNow")
                Button("Continue") { onContinue(selection) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("pricing.modeSheet.continue")
            }
            .buttonBorderShape(.capsule)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.medium)
        }
        .frame(width: 560)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.modeSheet")
    }
}

#Preview {
    PricingModeSheet(appName: "Lumen Journal", initialMode: .showSuggestions, onContinue: { _ in }, onNotNow: {})
}
