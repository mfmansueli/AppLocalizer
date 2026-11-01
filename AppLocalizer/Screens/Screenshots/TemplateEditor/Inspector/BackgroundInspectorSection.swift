//
//  BackgroundInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// Solid, gradient (two stops and an angle) or panorama. A slot with its
/// own background edits that one, and any slot can be given one, unless
/// the background is a panorama.
struct BackgroundInspectorSection: View {
    let model: TemplateEditorViewModel

    private static let kinds: [(TemplateBackground.Kind, String)] = [
        (.solid, String(localized: "Solid")), (.linear, String(localized: "Gradient")), (.panorama, String(localized: "Panorama")),
    ]

    var body: some View {
        if let background = model.effectiveBackground {
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
                    // A panorama's five stops take mini wells, and wrap rather
                    // than widen the inspector if even those don't fit.
                    FlowLayout(spacing: Spacing.xxSmall) {
                        ForEach(Array(background.stops.enumerated()), id: \.offset) { index, stop in
                            TemplateInspectorColorWell(label: String(localized: "Background color \(index + 1)"), color: stop, showsHex: false) {
                                model.setBackgroundStop(index, to: $0)
                            }
                        }
                    }
                    .controlSize(background.stops.count > 2 ? .mini : .small)
                }
                if background.kind == .linear {
                    TemplateInspectorSlider(label: String(localized: "Angle"), value: background.angle ?? 168, range: 0...360, unit: "°") {
                        model.setBackgroundAngle($0)
                    }
                    .accessibilityIdentifier("screenshots.template.angle")
                }
                if background.kind == .panorama {
                    Text("One background spans all \(model.slotCount) slots, so it continues when people swipe. Right-to-left locales get it reversed.")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                        .layoutPriority(1)
                }
                if model.hasOwnBackground {
                    HStack(spacing: Spacing.small) {
                        Text("Slot \(model.slot + 1) has its own background; these colors edit it.")
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                        Button("Use Template’s") { model.useTemplateBackground() }
                            .buttonStyle(.link)
                            .font(.caption)
                            .accessibilityIdentifier("screenshots.template.useTemplateBackground")
                    }
                } else if model.canGiveOwnBackground {
                    Button("Give Slot \(model.slot + 1) Its Own Background") { model.giveSlotOwnBackground() }
                        .accessibilityIdentifier("screenshots.template.ownBackground")
                }
            }
            .controlSize(.small)
        }
    }
}
