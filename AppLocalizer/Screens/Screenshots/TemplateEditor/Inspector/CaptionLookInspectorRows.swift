//
//  CaptionLookInspectorRows.swift
//  AppLocalizer
//

import SwiftUI

/// The headline's look: Uppercase, Emphasis (which line, and how it
/// differs) and Highlight bars with their color.
struct CaptionLookInspectorRows: View {
    let model: TemplateEditorViewModel

    var body: some View {
        TemplateInspectorRow(label: String(localized: "Uppercase")) {
            HStack(spacing: Spacing.small) {
                Toggle("Uppercase headline", isOn: Binding { model.isUppercase } set: { model.setUppercase($0) })
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                    .accessibilityIdentifier("screenshots.template.uppercase")
                Text("Uses each language’s own rules")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
        }
        TemplateInspectorPicker(
            String(localized: "Emphasis"), selection: Binding { model.emphasisLine } set: { model.setEmphasisLine($0) },
            identifier: "screenshots.template.emphasis"
        ) {
            Text("None").tag(TemplateEmphasis.Line?.none)
            Text("First line").tag(TemplateEmphasis.Line?.some(.first))
            Text("Last line").tag(TemplateEmphasis.Line?.some(.last))
        }
        if let style = model.emphasisStyle {
            TemplateInspectorPicker(
                String(localized: "Emphasized line"), selection: Binding { style } set: { model.setEmphasisStyle($0) },
                identifier: "screenshots.template.emphasisStyle"
            ) {
                ForEach(TemplateEditorViewModel.EmphasisStyle.allCases, id: \.self) { style in
                    Text(style.title).tag(style)
                }
            }
        }
        TemplateInspectorRow(label: String(localized: "Highlight")) {
            HStack(spacing: Spacing.small) {
                Toggle("Highlight bar behind each line", isOn: Binding { model.highlight != nil } set: { model.setHighlighted($0) })
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                    .accessibilityIdentifier("screenshots.template.highlight")
                if let highlight = model.highlight {
                    TemplateInspectorColorWell(label: String(localized: "Highlight color"), color: highlight.color, showsHex: false) {
                        model.setHighlightColor($0)
                    }
                }
            }
        }
    }
}
