//
//  DeviceAngleInspectorRows.swift
//  AppLocalizer
//

import SwiftUI

/// Angle · slot N: Rotate, Turn and Lean back for this slot's device.
struct DeviceAngleInspectorRows: View {
    let model: TemplateEditorViewModel

    var body: some View {
        let tilt = model.slotTilt
        Text("Angle · slot \(model.slot + 1)")
            .font(.callout.weight(.semibold))
            .padding(.top, Spacing.xxSmall)
        TemplateInspectorSlider(label: String(localized: "Rotate"), value: tilt.rotate, range: TemplateTilt.rotateRange, unit: "°") {
            model.setSlotTilt(TemplateTilt(rotate: $0, turn: tilt.turn, lean: tilt.lean))
        }
        .accessibilityIdentifier("screenshots.template.tilt.rotate")
        TemplateInspectorSlider(label: String(localized: "Turn"), value: tilt.turn, range: TemplateTilt.turnRange, unit: "°") {
            model.setSlotTilt(TemplateTilt(rotate: tilt.rotate, turn: $0, lean: tilt.lean))
        }
        .accessibilityIdentifier("screenshots.template.tilt.turn")
        TemplateInspectorSlider(label: String(localized: "Lean back"), value: tilt.lean, range: TemplateTilt.leanRange, unit: "°") {
            model.setSlotTilt(TemplateTilt(rotate: tilt.rotate, turn: tilt.turn, lean: $0))
        }
        .accessibilityIdentifier("screenshots.template.tilt.lean")
        Text("Right-to-left locales get the angle mirrored. The capture itself is never redrawn.")
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .layoutPriority(1)
    }
}
