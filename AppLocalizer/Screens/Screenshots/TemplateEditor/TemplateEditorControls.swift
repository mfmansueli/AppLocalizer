//
//  TemplateEditorControls.swift
//  AppLocalizer
//

import SwiftUI

/// The slot picker, the locale menu and the guides switch.
struct TemplateEditorControls: View {
    @Bindable var model: TemplateEditorViewModel

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Picker("Slot", selection: $model.slot) {
                ForEach(Array(model.slotTitles.enumerated()), id: \.offset) { index, title in
                    Text(title).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .accessibilityIdentifier("screenshots.template.slot")
            Picker("Locale", selection: $model.localeCode) {
                ForEach(model.localeOptions) { locale in
                    Text(locale.name).tag(locale.code)
                }
            }
            .fixedSize()
            .accessibilityIdentifier("screenshots.template.locale")
            Spacer(minLength: Spacing.small)
            Toggle("Safe areas and caption box", isOn: $model.showsGuides)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .font(.callout)
                .accessibilityIdentifier("screenshots.template.guides")
        }
        .controlSize(.small)
        .padding(.horizontal, Spacing.large)
        .padding(.bottom, Spacing.small)
    }
}
