//
//  AgeRatingOverrideSection.swift
//  AppLocalizer
//

import SwiftUI

/// "Rate higher than calculated": the rating to use and why. The reason is
/// kept on this Mac; App Store Connect only stores the rating.
struct AgeRatingOverrideSection: View {
    @Bindable var viewModel: AppInformationViewModel
    let preview: AgeRatingPreview
    let override: AgeRating?

    var body: some View {
        AppInformationFormSection(title: String(localized: "Override")) {
            AppInformationFormRow(label: String(localized: "Rate higher than calculated")) {
                HStack(spacing: Spacing.small) {
                    if let override {
                        Picker(String(localized: "Rating"), selection: Binding(get: { override }, set: { viewModel.setOverride($0) })) {
                            ForEach(AgeRating.overrides(above: preview.calculated)) { rating in
                                Text(rating.title).tag(rating)
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                        .accessibilityIdentifier("appInformation.age.overrideRating")
                    }
                    Toggle(
                        String(localized: "Rate higher than calculated"),
                        isOn: Binding(get: { override != nil }, set: { viewModel.setOverrideOn($0) })
                    )
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .disabled(override == nil && AgeRating.overrides(above: preview.calculated).isEmpty)
                    .accessibilityIdentifier("appInformation.age.override")
                }
            }
            if override != nil {
                Divider()
                AppInformationFormRow(label: String(localized: "Reason")) {
                    TextField(
                        String(localized: "Reason"),
                        text: Binding(get: { viewModel.notes.overrideReason }, set: { viewModel.setOverrideReason($0) }),
                        prompt: Text("Why this app should be rated higher")
                    )
                    .labelsHidden()
                    .frame(maxWidth: 320)
                    .accessibilityIdentifier("appInformation.age.overrideReason")
                }
            }
        }
    }
}
