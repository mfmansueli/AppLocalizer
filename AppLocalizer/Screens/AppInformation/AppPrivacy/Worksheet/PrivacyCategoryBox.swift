//
//  PrivacyCategoryBox.swift
//  AppLocalizer
//

import SwiftUI

/// One of the questionnaire's categories, e.g. Identifiers: how many of
/// its types are collected (reviewed answers only), and a row per type.
struct PrivacyCategoryBox: View {
    @Bindable var viewModel: AppPrivacyViewModel
    let category: PrivacyDataCategory
    let types: [PrivacyDataType]

    var body: some View {
        let mismatched = Set(viewModel.worksheet.mismatches.map(\.type))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(category.name)
                    .font(.callout.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Spacing.small)
                Text(viewModel.collectedSummary(for: category))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small + 2)
            .background(Palette.fill1)
            ForEach(types) { type in
                Divider()
                PrivacyDataTypeRow(viewModel: viewModel, type: type, isMismatched: mismatched.contains(type))
            }
            let hidden = viewModel.hiddenCount(in: category)
            if hidden > 0 {
                Divider()
                Button(String(localized: "\(hidden) more not collected")) {
                    viewModel.showsAllTypes = true
                }
                .buttonStyle(.link)
                .font(.caption)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .accessibilityIdentifier("appInformation.appPrivacy.category.\(category.rawValue).more")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.card, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.category.\(category.rawValue)")
    }
}
