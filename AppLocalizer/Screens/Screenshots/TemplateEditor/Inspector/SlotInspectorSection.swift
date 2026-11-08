//
//  SlotInspectorSection.swift
//  AppLocalizer
//

import SwiftUI

/// This slot: Standard, Hero, Two phones or Reviews, a headline size
/// override, the overrides it has, each clearable, and Reset Slot.
struct SlotInspectorSection: View {
    let model: TemplateEditorViewModel

    var body: some View {
        TemplateInspectorSection(title: model.slotHeader) {
            if model.hasSlotOverrides {
                Button("Reset Slot") { model.resetSlot() }
                    .buttonStyle(.link)
                    .font(.caption)
                    .accessibilityIdentifier("screenshots.template.resetSlot")
            }
        } content: {
            TemplateInspectorPicker(
                String(localized: "Layout"), selection: Binding { model.slotLayout } set: { model.setSlotLayout($0) },
                identifier: "screenshots.template.slotLayout"
            ) {
                Text("Standard").tag(TemplateSlot.Layout.standard)
                Text("Hero").tag(TemplateSlot.Layout.hero)
                Text("Two phones").tag(TemplateSlot.Layout.pair)
                Text("Reviews").tag(TemplateSlot.Layout.quotes)
            }
            TemplateInspectorSlider(label: String(localized: "Headline size"), value: model.slotHeadlineSize, range: 72...150, step: 2, unit: " u") {
                model.setSlotHeadlineSize($0)
            }
            .accessibilityIdentifier("screenshots.template.slotSize")
            ForEach(model.slotOverrides) { change in
                HStack(spacing: Spacing.xSmall) {
                    Text("\(TemplateSchema.title(for: change.fieldPath)): \(change.newText)")
                        .font(.caption)
                        .monospacedDigit()
                    Text("template \(change.oldText)")
                        .font(.caption)
                        .foregroundStyle(Palette.label2)
                    Spacer(minLength: 0)
                    Button {
                        model.clearOverride(change)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Palette.label3)
                    .help(Text("Follow the template here"))
                    .accessibilityLabel(Text("Clear the \(TemplateSchema.title(for: change.fieldPath)) override"))
                    .accessibilityIdentifier("screenshots.template.clearOverride.\(change.fieldPath)")
                }
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xxSmall)
                .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field))
            }
            Text(model.slotNote)
                .font(.caption)
                .foregroundStyle(Palette.label2)
                .layoutPriority(1)
        }
        .controlSize(.small)
        .accessibilityIdentifier("screenshots.template.slotSection")
    }
}
