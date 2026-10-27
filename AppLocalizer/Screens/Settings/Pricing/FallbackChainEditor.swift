//
//  FallbackChainEditor.swift
//  AppLocalizer
//

import SwiftUI

/// Settings → Pricing → Fallback chain → Edit…: which steps fill the
/// territories the default index doesn't cover. Other indices come first,
/// then the region median; Apple's equalized price is always the last resort.
struct FallbackChainEditor: View {
    @Binding var strategy: PricingStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Fallback chain")
                .font(.headline)
            Text("When \(strategy.indexSource.name) has no value for a territory, try in order:")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Self.optionalSteps(chosen: strategy.indexSource), id: \.self) { step in
                Toggle(step.title(chosen: strategy.indexSource), isOn: binding(for: step))
            }
            Toggle(FallbackStep.equalized.title(chosen: strategy.indexSource), isOn: .constant(true))
                .disabled(true)
                .help(Text("Always the last resort"))
        }
        .toggleStyle(.checkbox)
        .padding(Spacing.large)
        .frame(width: 300, alignment: .leading)
    }

    /// Every step that can be switched: the other indices, then the region
    /// median.
    static func optionalSteps(chosen: PriceIndexSource) -> [FallbackStep] {
        PriceIndexSource.allCases.filter { $0 != chosen && $0 != .custom }.map(FallbackStep.index) + [.regionMedian]
    }

    private func binding(for step: FallbackStep) -> Binding<Bool> {
        Binding(
            get: { strategy.fallback.contains(step) },
            set: { isOn in
                let chosen = strategy.indexSource
                var enabled = Set(strategy.fallback)
                if isOn { enabled.insert(step) } else { enabled.remove(step) }
                // Kept in the editor's order, with equalized last.
                let fallback = Self.optionalSteps(chosen: chosen).filter(enabled.contains) + [.equalized]
                strategy.customize { $0.fallback = fallback }
            }
        )
    }
}
