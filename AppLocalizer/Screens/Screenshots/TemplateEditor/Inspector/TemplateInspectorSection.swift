//
//  TemplateInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// One inspector section: an uppercase title, an optional control on the
/// title's line (Device's switch), and its rows.
struct TemplateInspectorSection<Accessory: View, Content: View>: View {
    let title: String
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text(title)
                    .textCase(.uppercase)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                Spacer(minLength: Spacing.small)
                accessory()
            }
            content()
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}
