//
//  RightToLeftInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Mirroring for Arabic and Hebrew.
struct RightToLeftInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        if let template = model.template {
            TemplateInspectorSection(title: String(localized: "Right to left")) {
                Toggle("Mirror the layout for Arabic and Hebrew", isOn: Binding { template.rightToLeft.mirror } set: { model.set("rtl.mirror", to: .bool($0)) })
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                    .accessibilityIdentifier("screenshots.template.mirror")
            } content: {
                Text("Mirror the layout for Arabic and Hebrew")
                    .font(.callout)
                Text("Flips device offsets, start-aligned captions and the panorama. Captures are never mirrored: they’re your real interface.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .layoutPriority(1)
            }
        }
    }
}
