//
//  NewLanguagesSheet.swift
//  AppLocalizer
//

import SwiftUI

/// "Languages in the app, not on the App Store": each language the project
/// has and the App Store page doesn't, checked to add, with how much of it is
/// translated and whether it's drafted, then Cancel and Add n Languages.
/// Added ones stay checked with an "Added" pill.
struct NewLanguagesSheet: View {
    @Bindable var viewModel: StorePageViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let rows = viewModel.newLanguageRows
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Languages in the app, not on the App Store")
                    .font(.title2.weight(.semibold))
                Text(viewModel.newLanguagesSheetSubtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            if index > 0 { Divider() }
                            NewLanguageSheetRow(row: row, isOn: row.isAdded || viewModel.languageSelection.contains(row.locale)) {
                                viewModel.toggleNewLanguage(row.locale)
                            }
                        }
                    }
                    .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radius.banner, style: .continuous).strokeBorder(Palette.separator, lineWidth: 1))
                    Text("Suggest Everything includes these too, so one prompt drafts every new page.")
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                }
                .padding(.horizontal, Spacing.xLarge)
                .padding(.bottom, Spacing.medium)
            }
            .scrollBounceBehavior(.basedOnSize)
            Divider()
            HStack(spacing: Spacing.small) {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("storePage.languagesSheet.cancel")
                Spacer()
                Button(viewModel.addSelectedLanguagesTitle) {
                    viewModel.addSelectedLanguages()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.selectedNewLanguages.isEmpty)
                .accessibilityIdentifier("storePage.languagesSheet.add")
            }
            .buttonBorderShape(.capsule)
            .padding(Spacing.large)
        }
        .frame(width: 640)
        .frame(maxHeight: 620)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.languagesSheet")
    }
}
