//
//  AppInformationPreviewPane.swift
//  AppLocalizer
//

import SwiftUI

/// Beside an App Information page: the Information and Accessibility
/// sections of the App Store page, as they are now or with what's suggested
/// on top.
struct AppInformationPreviewPane: View {
    let viewModel: AppInformationViewModel

    @Environment(AppSummaryStore.self) private var summaries
    @State private var showsSuggested = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Text("On the App Store")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Preview", selection: $showsSuggested) {
                    Text("Now").tag(false)
                    Text("Suggested").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
                .accessibilityIdentifier("appInformation.preview.mode")
            }
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Information")
                    .font(.subheadline.weight(.semibold))
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 5) {
                    row(String(localized: "Category"), category)
                    let rating = viewModel.ratingPreview?.effective.title ?? String(localized: "Not rated yet")
                    row(String(localized: "Age Rating"), AppStorePreviewText(value: rating))
                    row(String(localized: "Copyright"), copyright)
                    if let languages {
                        row(String(localized: "Languages"), AppStorePreviewText(value: languages))
                    }
                }
                let families = viewModel.accessibilityCards.map(\.family)
                if !families.isEmpty {
                    Divider()
                    Text("Accessibility")
                        .font(.subheadline.weight(.semibold))
                    ForEach(families) { family in
                        accessibility(family)
                    }
                }
            }
            .font(.caption)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.content, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 0.5)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Preview on the App Store"))
            .accessibilityIdentifier("appInformation.preview")
        }
        .frame(width: 236)
    }

    private func row(_ title: String, _ text: AppStorePreviewText) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(Palette.label2)
            Text(text.value.isEmpty ? "—" : text.value)
                .modifier(AppStorePreviewHighlight(isOn: text.isSuggested))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func suggested(_ field: AppInformationSuggestionField) -> AppStorePreviewText? {
        guard showsSuggested, let suggestion = viewModel.shownSuggestion(field) else { return nil }
        return AppStorePreviewText(value: AppInformationSuggestionSlot.field(field).displayValue(suggestion.value), isSuggested: true)
    }

    private var category: AppStorePreviewText {
        if let primary = suggested(.primaryCategory) { return primary }
        let current = viewModel.general?.primaryCategory.map { AppCategory.name(for: $0) } ?? ""
        return AppStorePreviewText(value: current)
    }

    private var copyright: AppStorePreviewText {
        suggested(.copyright) ?? AppStorePreviewText(value: viewModel.general?.copyright ?? "")
    }

    /// "English and 11 more".
    private var languages: String? {
        guard let summary = summaries.storePage[viewModel.app.id]?.value, let first = summary.localeCodes.first,
              let locale = StoreLocaleCatalog.locale(code: first) else { return nil }
        let name = LanguageBarModel.shortName(locale)
        return summary.localeCount > 1 ? String(localized: "\(name) and \(summary.localeCount - 1) more") : name
    }

    private func accessibility(_ family: DeviceFamily) -> some View {
        let chips = accessibilityChips(family)
        return VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(family.name)
                .font(.caption2)
                .foregroundStyle(Palette.label2)
            if chips.isEmpty {
                Text("No details provided")
                    .font(.caption2)
                    .foregroundStyle(Palette.label3)
            } else {
                FlowLayout(spacing: Spacing.xxSmall) {
                    ForEach(chips, id: \.value) { chip in
                        Text(chip.value)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Palette.fill2, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .modifier(AppStorePreviewHighlight(isOn: chip.isSuggested))
                    }
                }
            }
        }
    }

    /// What the family declares, in Apple's order, with suggested features.
    private func accessibilityChips(_ family: DeviceFamily) -> [AppStorePreviewText] {
        let card = viewModel.accessibilityCards.first { $0.family == family }
        let current = card?.shown?.features ?? []
        return family.features.compactMap { feature in
            let slot = AppInformationSuggestionSlot.accessibility(family, feature)
            let suggestion = showsSuggested ? viewModel.shownSuggestion(slot) : nil
            if suggestion?.value == AppInformationSuggestionSlot.supported {
                return AppStorePreviewText(value: feature.name, isSuggested: !current.contains(feature))
            }
            if suggestion?.value == AppInformationSuggestionSlot.unsupported { return nil }
            return current.contains(feature) ? AppStorePreviewText(value: feature.name) : nil
        }
    }
}
