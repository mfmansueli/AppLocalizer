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
            TemplateInspectorPicker(
                String(localized: "Display type"), selection: Binding { model.screenshots.displayType } set: { model.screenshots.displayType = $0 },
                identifier: "screenshots.template.displayType"
            ) {
                ForEach(model.screenshots.renderedDisplays) { display in
                    Text(display.title).tag(display)
                }
            }
            TemplateInspectorPicker(
                String(localized: "Orientation"), selection: Binding { model.orientation } set: { model.setOrientation($0) },
                identifier: "screenshots.template.orientation"
            ) {
                ForEach(ScreenshotOrientation.allCases, id: \.self) { orientation in
                    Text(orientation.title).tag(orientation)
                }
            }
            // Mac's screenshots are always landscape.
            .disabled(model.screenshots.displayType.isAlwaysLandscape)
            Text(model.outputText)
                .font(.caption.monospaced())
                .foregroundStyle(Palette.label2)
                .textSelection(.enabled)
        }
        .controlSize(.small)
    }
}
