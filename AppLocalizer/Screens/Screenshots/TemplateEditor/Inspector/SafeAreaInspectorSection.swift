//
//  SafeAreaInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// The top and side margins captions stay inside.
struct SafeAreaInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        if let safeArea = model.template?.safeArea {
            TemplateInspectorSection(title: String(localized: "Safe areas")) {
                TemplateInspectorSlider(
                    label: String(localized: "Top"), value: percent(safeArea.top), range: 3...12, step: 0.5, unit: "%", fractionDigits: 1
                ) {
                    model.set("safe.top", to: .double($0 / 100))
                }
                TemplateInspectorSlider(
                    label: String(localized: "Sides"), value: percent(safeArea.side), range: 4...12, step: 0.5, unit: "%", fractionDigits: 1
                ) {
                    model.set("safe.side", to: .double($0 / 100))
                }
                Text("Captions stay inside these margins. The App Store rounds screenshot corners.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
            }
            .controlSize(.small)
        }
    }

    private func percent(_ fraction: Double) -> Double {
        (fraction * 1000).rounded() / 10
    }
}
