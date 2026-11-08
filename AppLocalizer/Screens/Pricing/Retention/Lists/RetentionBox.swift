//
//  RetentionBox.swift
//  AppLocalizer
//

import SwiftUI

/// A titled box on the left of the Retention page: the title, something
/// on its right, then rows edge to edge.
struct RetentionBox<Trailing: View, Content: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    var body: some View {
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Spacing.small)
                    trailing()
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                Divider()
                content()
            }
        }
    }
}
