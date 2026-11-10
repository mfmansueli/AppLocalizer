//
//  AppInformationPageColumn.swift
//  AppLocalizer
//

import SwiftUI

/// General · Age Rating · Accessibility · App Privacy · App Review · Export
/// Compliance, under the section's name, each with its status and how many
/// suggestions wait on it.
struct AppInformationPageColumn: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        List(selection: selection) {
            ForEach(AppInformationPage.allCases) { page in
                AppInformationPageRow(
                    page: page,
                    status: viewModel.pageColumnStatus(for: page),
                    suggestionCount: viewModel.suggestionCount(on: page),
                    comingCount: viewModel.comingCount(on: page),
                    isUpToDate: viewModel.isPageUpToDate(page),
                    hasPendingChanges: viewModel.hasPendingChanges(on: page)
                )
                .tag(page)
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Palette.sectionAppInformation, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                Text("App Information")
                    .font(.headline)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, Spacing.small)
        }
        .safeAreaInset(edge: .bottom) {
            Text("Details Apple asks for with each version. Most never show on the page.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.large)
                .padding(.bottom, Spacing.medium)
        }
        .frame(width: 200)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("App Information pages"))
        .accessibilityIdentifier("appInformation.pageColumn")
    }

    private var selection: Binding<AppInformationPage?> {
        Binding(get: { viewModel.page }, set: { page in if let page { viewModel.page = page } })
    }
}
