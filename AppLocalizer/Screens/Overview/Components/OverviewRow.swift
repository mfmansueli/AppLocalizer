//
//  OverviewRow.swift
//  AppLocalizer
//

import SwiftUI

/// A label–value line with a hairline above it, as in the Subscriptions and
/// App Information cards.
struct OverviewRow<Label: View, Value: View>: View {
    @ViewBuilder var label: () -> Label
    @ViewBuilder var value: () -> Value

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                label()
                    .frame(maxWidth: .infinity, alignment: .leading)
                value()
            }
            .font(.callout)
            .padding(.vertical, 5)
        }
        .accessibilityElement(children: .combine)
    }
}
