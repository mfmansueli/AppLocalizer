//
//  DeviceInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// The device frame: on or off, finish and width.
struct DeviceInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        if let device = model.template?.device {
            TemplateInspectorSection(title: String(localized: "Device")) {
                Toggle("Show device frame", isOn: Binding { model.showsDevice } set: { model.set("device.show", to: .bool($0)) })
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .controlSize(.mini)
                    .disabled(model.template?.caption.placement == .band)
                    .accessibilityIdentifier("screenshots.template.device")
            } content: {
                if model.showsDevice {
                    TemplateInspectorRow(label: String(localized: "Frame")) {
                        Text(model.frameName)
                            .font(.callout)
                    }
                    TemplateInspectorRow(label: String(localized: "Finish")) {
                        Picker("Finish", selection: Binding { device.color.uppercased() } set: { model.set("device.color", to: .string($0)) }) {
                            ForEach(TemplateEditorViewModel.deviceFinishes, id: \.color) { finish in
                                Text(finish.title).tag(finish.color)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                    }
                    TemplateInspectorSlider(
                        label: String(localized: "Width"), value: (device.width * 100).rounded(), range: 60...90,
                        unit: "%"
                    ) {
                        model.set("device.width", to: .double($0 / 100))
                    }
                    .accessibilityIdentifier("screenshots.template.deviceWidth")
                } else {
                    Text("The capture fills the canvas. Captures must match the display type’s size, or the check fails.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .layoutPriority(1)
                }
            }
            .controlSize(.small)
        }
    }
}
