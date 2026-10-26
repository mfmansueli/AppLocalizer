//
//  PricingViewModel+StrategyBindings.swift
//  AppLocalizer
//

import SwiftUI

/// Bindings the inspector's controls edit the strategy through, so every
/// change goes through `editStrategy` and turns the strategy custom.
extension PricingViewModel {
    func strategyBinding<Value>(_ keyPath: WritableKeyPath<PricingStrategy, Value>) -> Binding<Value> {
        Binding(
            get: { self.strategy.strategy[keyPath: keyPath] },
            set: { value in self.editStrategy { $0[keyPath: keyPath] = value } }
        )
    }

    /// A slider's view of a decimal fraction, in steps of 0.01.
    func fractionBinding(_ keyPath: WritableKeyPath<PricingStrategy, Decimal>) -> Binding<Double> {
        Binding(
            get: { self.strategy.strategy[keyPath: keyPath].doubleValue },
            set: { value in
                let rounded = Decimal(exactly: (value * 100).rounded() / 100)
                guard rounded != self.strategy.strategy[keyPath: keyPath] else { return }
                self.editStrategy { $0[keyPath: keyPath] = rounded }
            }
        )
    }
}
