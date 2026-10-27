//
//  CanvasInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Display type, orientation, and the output size and API display type.
struct CanvasInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        TemplateInspectorSection(title: String(localized: "Canvas")) {
            TemplateInspectorRow(label: String(localized: "Display type")) {
                Picker("Display type", selection: Binding { model.screenshots.displayType } set: { model.screenshots.displayType = $0 }) {
                    ForEach(ScreenshotDisplayType.rendered) { display in
                        Text(display.title).tag(display)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("screenshots.template.displayType")
            }
            TemplateInspectorRow(label: String(localized: "Orientation")) {
                Picker("Orientation", selection: Binding { model.orientation } set: { model.setOrientation($0) }) {
                    ForEach(ScreenshotOrientation.allCases, id: \.self) { orientation in
                        Text(orientation.title).tag(orientation)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("screenshots.template.orientation")
            }
            Text(model.outputText)
                .font(.caption.monospaced())
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
        }
        .controlSize(.small)
    }
}
