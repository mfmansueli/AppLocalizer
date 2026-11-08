//
//  DeviceInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// The device frame: on or off, finish, color, width and this slot's
/// angle.
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
                    TemplateInspectorPicker(
                        String(localized: "Finish"), selection: Binding { device.color.uppercased() } set: { model.set("device.color", to: .string($0)) }
                    ) {
                        ForEach(TemplateEditorViewModel.deviceFinishes, id: \.color) { finish in
                            Text(finish.title).tag(finish.color)
                        }
                    }
                    TemplateInspectorRow(label: String(localized: "Color")) {
                        TemplateInspectorColorWell(label: String(localized: "Frame color"), color: model.slotTemplate?.device.color ?? device.color) {
                            model.set("device.color", to: .string($0))
                        }
                    }
                    TemplateInspectorSlider(
                        label: String(localized: "Width"), value: (device.width * 100).rounded(), range: 60...90,
                        unit: "%"
                    ) {
                        model.set("device.width", to: .double($0 / 100))
                    }
                    .accessibilityIdentifier("screenshots.template.deviceWidth")
                    DeviceAngleInspectorRows(model: model)
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
