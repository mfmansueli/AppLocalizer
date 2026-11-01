//
//  DecorationsInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Decorations · Slot N: each of the slot's shapes, laurels and badges
/// with its color (and a rating's value), Remove, and the four Add
/// buttons.
struct DecorationsInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        TemplateInspectorSection(title: model.decorationsTitle) {
            let decorations = model.slotDecorations
            ForEach(Array(decorations.enumerated()), id: \.offset) { index, decoration in
                DecorationInspectorRow(model: model, decoration: decoration, index: index)
            }
            if decorations.isEmpty {
                Text("None on this slot.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            FlowLayout(spacing: Spacing.xSmall) {
                ForEach(TemplateEditorViewModel.DecorationPreset.allCases) { preset in
                    Button(preset.title) { model.addDecoration(preset) }
                        .accessibilityIdentifier("screenshots.template.addDecoration.\(preset.rawValue)")
                }
            }
            Text(model.ratingNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .layoutPriority(1)
        }
        .controlSize(.small)
        .accessibilityIdentifier("screenshots.template.decorations")
    }
}
