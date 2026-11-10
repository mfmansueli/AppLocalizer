//
//  AccessibilitySuggestionsSection.swift
//  AppLocalizer
//

import SwiftUI

/// Above Accessibility's cards: one device at a time, its suggestion bar,
/// and each suggested feature with Apple's meaning, its answer now and the
/// suggestion. Accepting queues the device's declaration, as Save in the
/// editor does; a feature that needs a person to check the screens
/// (Sufficient Contrast) says so in its meaning.
struct AccessibilitySuggestionsSection: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        if viewModel.showsSuggestions(on: .accessibility), let family = viewModel.shownAccessibilitySuggestionFamily {
            VStack(alignment: .leading, spacing: Spacing.small) {
                devicePicker(selected: family)
                AppInformationSuggestionsPanel(viewModel: viewModel, scope: .accessibility(family))
                let slots = viewModel.suggestionSlots(in: .accessibility(family)).filter { slot in
                    viewModel.shownSuggestion(slot) != nil || viewModel.provenance(slot) != nil || viewModel.isComing(slot)
                }
                if !slots.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(slots.enumerated()), id: \.element) { index, slot in
                            if index > 0 { Divider() }
                            row(slot)
                        }
                    }
                    .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 0.5))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.accessibility.suggestions")
        }
    }

    @ViewBuilder
    private func devicePicker(selected: DeviceFamily) -> some View {
        let families = viewModel.accessibilitySuggestionFamilies
        if families.count > 1 {
            BadgedSegments(
                label: String(localized: "Device"),
                options: families.map { family in
                    let scope = SuggestionScope.accessibility(family)
                    return (family, Self.deviceTitle(family, coming: viewModel.comingCount(in: scope)), viewModel.suggestionCount(in: scope))
                },
                selection: Binding(get: { selected }, set: { viewModel.accessibilitySuggestionFamily = $0 })
            )
            .accessibilityIdentifier("appInformation.accessibility.suggestions.device")
        }
    }

    /// "Apple Watch", with "· 3 coming" while Suggest Everything owes it
    /// more.
    private static func deviceTitle(_ family: DeviceFamily, coming: Int) -> String {
        coming > 0 ? family.name + " · " + String(localized: "\(coming) coming") : family.name
    }

    private func row(_ slot: AppInformationSuggestionSlot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if case let .accessibility(_, feature) = slot {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.name)
                        Text(feature.meaning)
                            .font(.caption)
                            .foregroundStyle(Palette.label2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(slot.displayValue(viewModel.suggestionValue(slot)))
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                .padding(.horizontal, Spacing.medium + 2)
                .padding(.vertical, Spacing.small + 1)
                .accessibilityElement(children: .combine)
            }
            AppInformationFieldSuggestions(viewModel: viewModel, slot: slot)
        }
    }
}
