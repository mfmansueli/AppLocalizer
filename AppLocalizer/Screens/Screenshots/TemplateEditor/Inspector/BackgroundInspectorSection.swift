//
//  BackgroundInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Solid, gradient (two stops and an angle) or panorama.
struct BackgroundInspectorSection: View {
    let model: TemplateEditorViewModel

    private static let kinds: [(TemplateBackground.Kind, String)] = [
        (.solid, String(localized: "Solid")), (.linear, String(localized: "Gradient")), (.panorama, String(localized: "Panorama")),
    ]

    var body: some View {
        if let background = model.template?.background {
            TemplateInspectorSection(title: String(localized: "Background")) {
                Picker("Background", selection: Binding { background.kind } set: { model.setBackgroundKind($0) }) {
                    ForEach(Self.kinds, id: \.0) { kind, title in
                        Text(title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .accessibilityIdentifier("screenshots.template.backgroundKind")
                TemplateInspectorRow(label: String(localized: "Colors")) {
                    HStack(spacing: Spacing.xxSmall) {
                        ForEach(Array(background.stops.enumerated()), id: \.offset) { index, stop in
                            TemplateInspectorColorWell(label: String(localized: "Background color \(index + 1)"), color: stop, showsHex: false) {
                                model.setBackgroundStop(index, to: $0)
                            }
                        }
                    }
                }
                if background.kind == .linear {
                    TemplateInspectorSlider(label: String(localized: "Angle"), value: background.angle ?? 168, range: 0...360, unit: "°") {
                        model.set("bg.angle", to: .double($0))
                    }
                    .accessibilityIdentifier("screenshots.template.angle")
                }
                if background.kind == .panorama {
                    Text("One background spans all \(model.slotCount) slots, so it continues when people swipe. Right-to-left locales get it reversed.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .layoutPriority(1)
                }
            }
            .controlSize(.small)
        }
    }
}
