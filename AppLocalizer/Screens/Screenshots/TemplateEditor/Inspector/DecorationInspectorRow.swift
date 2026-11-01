//
//  DecorationInspectorRow.swift
//  AppLocalizer
//

import SwiftUI

/// One decoration on the slot: its name, a rating's value, its color and
/// Remove.
struct DecorationInspectorRow: View {
    let model: TemplateEditorViewModel
    let decoration: TemplateDecoration
    let index: Int
    @State private var value = ""

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Text(decoration.title)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            if decoration.isRating {
                TextField("Value", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 58)
                    .onSubmit { model.setDecorationValue(value, at: index) }
                    .accessibilityLabel(Text("Value shown on the \(decoration.title)"))
                    .accessibilityIdentifier("screenshots.template.decorationValue.\(index)")
            }
            TemplateInspectorColorWell(label: String(localized: "\(decoration.title) color"), color: decoration.color, showsHex: false) {
                model.setDecorationColor($0, at: index)
            }
            Button("Remove") { model.removeDecoration(at: index) }
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityLabel(Text("Remove \(decoration.title)"))
                .accessibilityIdentifier("screenshots.template.removeDecoration.\(index)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.template.decoration.\(index)")
        .onAppear { value = decoration.value ?? "" }
        .onChange(of: decoration.value) { _, newValue in value = newValue ?? "" }
    }
}
