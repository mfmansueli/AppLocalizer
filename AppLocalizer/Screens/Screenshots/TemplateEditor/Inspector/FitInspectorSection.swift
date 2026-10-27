//
//  FitInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Maximum lines, smallest size, shrink to fit and hyphenation, and the
/// caption box they reserve.
struct FitInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        if let template = model.template {
            let headline = template.caption.headline
            TemplateInspectorSection(title: String(localized: "Fit")) {
                TemplateInspectorRow(label: String(localized: "Max lines")) {
                    Picker("Max lines", selection: Binding { headline.maxLines } set: { model.set("caption.headline.maxLines", to: .int($0)) }) {
                        ForEach(1...3, id: \.self) { lines in
                            Text("\(lines)").tag(lines)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .accessibilityIdentifier("screenshots.template.maxLines")
                }
                TemplateInspectorSlider(label: String(localized: "Smallest size"), value: headline.min, range: 56...120, step: 2, unit: " u") {
                    model.set("caption.headline.min", to: .double(min($0, headline.size)))
                }
                .accessibilityIdentifier("screenshots.template.minimumSize")
                TemplateInspectorRow(label: String(localized: "Shrink to fit")) {
                    Toggle("Shrink to fit", isOn: Binding { template.fit.shrink } set: { model.set("fit.shrink", to: .bool($0)) })
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .controlSize(.mini)
                        .accessibilityIdentifier("screenshots.template.shrink")
                }
                TemplateInspectorRow(label: String(localized: "Hyphenate")) {
                    HStack(spacing: Spacing.small) {
                        Toggle("Hyphenate long words", isOn: Binding { template.fit.hyphenate } set: { model.set("fit.hyphenate", to: .bool($0)) })
                            .toggleStyle(.switch)
                            .labelsHidden()
                            .controlSize(.mini)
                            .accessibilityIdentifier("screenshots.template.hyphenate")
                        Text("Long words only")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                    }
                }
                Text(model.captionBoxText)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
            }
            .controlSize(.small)
        }
    }
}
