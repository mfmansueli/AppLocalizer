//
//  TemplateInspectorColorWell.swift
//  AppLocalizer
//

import AppKit
import SwiftUI

/// A color well for a template color, with its hex beside it.
struct TemplateInspectorColorWell: View {
    let label: String
    /// `#RRGGBB`, or `rgba()`.
    let color: String
    var showsHex = true
    let onChange: (String) -> Void

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            ColorPicker(selection: binding, supportsOpacity: false) {
                Text(label)
            }
            .labelsHidden()
            .accessibilityLabel(Text(label))
            if showsHex {
                Text((TemplateColor(color) ?? .white).hexString)
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
            }
        }
    }

    private var binding: Binding<Color> {
        Binding {
            (TemplateColor(color) ?? .white).color
        } set: { newColor in
            guard let srgb = NSColor(newColor).usingColorSpace(.sRGB) else { return }
            let picked = TemplateColor(red: srgb.redComponent, green: srgb.greenComponent, blue: srgb.blueComponent)
            onChange(picked.hexString)
        }
    }
}
