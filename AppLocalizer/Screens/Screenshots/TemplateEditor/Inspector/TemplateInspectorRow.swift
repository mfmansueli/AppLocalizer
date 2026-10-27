//
//  TemplateInspectorRow.swift
//  AppLocalizer
//

import SwiftUI

/// A label on the left and its control on the right.
struct TemplateInspectorRow<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(label)
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(width: 92, alignment: .leading)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
