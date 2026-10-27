//
//  FontsInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// One row per script: the display font draws it, or a fallback picker
/// and a status. A script with neither fails for its locales.
struct FontsInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        TemplateInspectorSection(title: String(localized: "Fonts by script")) {
            Text(model.displayCoverageText)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .layoutPriority(1)
            ForEach(model.fontRows) { row in
                TemplateInspectorRow(label: row.script.title) {
                    HStack(spacing: Spacing.xSmall) {
                        if row.isDrawnByDisplayFont {
                            Text("Display font")
                                .font(.callout)
                                .foregroundStyle(Palette.label2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Picker("Fallback font for \(row.script.title)", selection: Binding { row.fallback } set: { model.setFallback($0, for: row.script) }) {
                                Text("None").tag(String?.none)
                                ForEach(row.options, id: \.self) { font in
                                    Text(model.fontTitle(font)).tag(Optional(font))
                                }
                            }
                            .labelsHidden()
                            .accessibilityIdentifier("screenshots.template.fallback.\(row.script.rawValue)")
                        }
                        status(row)
                    }
                }
            }
        }
        .controlSize(.small)
        .accessibilityIdentifier("screenshots.template.fonts")
    }

    @ViewBuilder
    private func status(_ row: FontScriptRow) -> some View {
        if row.hasProblem {
            Pill(text: row.problemText, style: .danger)
                .help(row.status)
                .accessibilityIdentifier("screenshots.template.fontProblem.\(row.script.rawValue)")
        } else {
            Image(systemName: "checkmark")
                .foregroundStyle(Palette.label2)
                .help(row.status)
                .accessibilityLabel(Text(row.status))
        }
    }
}
