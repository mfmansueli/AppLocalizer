//
//  TemplateInspector.swift
//  AppLocalizer
//

import SwiftUI

/// The template's settings, section by section (design README §2
/// "Inspector"). Every control is an operation the applier checks.
struct TemplateInspector: View {
    let model: TemplateEditorViewModel

    var body: some View {
        ScrollView {
            if model.template != nil {
                VStack(spacing: 0) {
                    CanvasInspectorSection(model: model)
                    Divider()
                    BackgroundInspectorSection(model: model)
                    Divider()
                    DeviceInspectorSection(model: model)
                    Divider()
                    CaptionInspectorSection(model: model)
                    Divider()
                    DecorationsInspectorSection(model: model)
                    Divider()
                    FitInspectorSection(model: model)
                    Divider()
                    FontsInspectorSection(model: model)
                    Divider()
                    RightToLeftInspectorSection(model: model)
                    Divider()
                    SafeAreaInspectorSection(model: model)
                    Divider()
                    SlotInspectorSection(model: model)
                }
            }
        }
        .background(Palette.content)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Template inspector"))
        .accessibilityIdentifier("screenshots.template.inspector")
    }
}
