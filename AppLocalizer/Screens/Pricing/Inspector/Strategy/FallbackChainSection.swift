//
//  FallbackChainSection.swift
//  AppLocalizer
//

import SwiftUI

/// What fills the gaps where the chosen index has no data, in order.
struct FallbackChainSection: View {
    let viewModel: PricingViewModel

    var body: some View {
        let model = viewModel.strategy
        let strategy = model.strategy
        InspectorSection(.fallback, in: model) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Fills the gaps where the chosen index has no data. \(model.fallbackCount) territories use a fallback.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(strategy.indexSource.name).font(.callout.weight(.medium))
                    Spacer()
                    Pill(text: String(localized: "chosen"), style: .accent)
                }
                .padding(.vertical, 2)
                ForEach(Array(steps.enumerated()), id: \.element) { position, step in
                    HStack(spacing: Spacing.xSmall) {
                        Text(position + 2, format: .number)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Palette.label3)
                        Text(step.title(chosen: strategy.indexSource)).font(.callout)
                        Spacer(minLength: Spacing.xSmall)
                        Button { move(step, by: -1) } label: { Image(systemName: "arrow.up") }
                            .disabled(position == 0)
                            .accessibilityLabel(String(localized: "Move up"))
                        Button { move(step, by: 1) } label: { Image(systemName: "arrow.down") }
                            .disabled(position == steps.count - 1)
                            .accessibilityLabel(String(localized: "Move down"))
                        Button { remove(step) } label: { Image(systemName: "xmark") }
                            .accessibilityLabel(String(localized: "Remove \(step.title(chosen: strategy.indexSource))"))
                    }
                    .buttonStyle(.borderless)
                    .padding(.vertical, 1)
                }
                if !missing.isEmpty {
                    Menu("Add Fallback") {
                        ForEach(missing, id: \.self) { step in
                            Button(step.title(chosen: strategy.indexSource)) { add(step) }
                        }
                    }
                    .fixedSize()
                    .controlSize(.small)
                    .accessibilityIdentifier("pricing.fallback.add")
                }
            }
        }
    }

    private var steps: [FallbackStep] {
        let strategy = viewModel.strategy.strategy
        return strategy.fallback.filter { $0 != .index(strategy.indexSource) }
    }

    private var missing: [FallbackStep] {
        let strategy = viewModel.strategy.strategy
        let options = PriceIndexSource.allCases
            .filter { $0 != strategy.indexSource && viewModel.strategy.index($0) != nil }
            .map(FallbackStep.index) + [.regionMedian, .equalized]
        return options.filter { !strategy.fallback.contains($0) }
    }

    private func move(_ step: FallbackStep, by offset: Int) {
        viewModel.editStrategy { strategy in
            guard let index = strategy.fallback.firstIndex(of: step) else { return }
            let target = index + offset
            guard strategy.fallback.indices.contains(target) else { return }
            strategy.fallback.swapAt(index, target)
        }
    }

    private func remove(_ step: FallbackStep) {
        viewModel.editStrategy { $0.fallback.removeAll { $0 == step } }
    }

    private func add(_ step: FallbackStep) {
        viewModel.editStrategy { $0.fallback.append(step) }
    }
}
