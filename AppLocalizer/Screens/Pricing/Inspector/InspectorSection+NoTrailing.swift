//
//  InspectorSection+NoTrailing.swift
//  AppLocalizer
//

import SwiftUI

/// Sections with nothing next to their title.
extension InspectorSection where Trailing == EmptyView {
    init(_ section: StrategyInspectorSection, in model: PricingStrategyModel, @ViewBuilder content: @escaping () -> Content) {
        self.init(section, in: model, trailing: { EmptyView() }, content: content)
    }
}
