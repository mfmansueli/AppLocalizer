//
//  AppInformationPageColumn.swift
//  AppLocalizer
//

import SwiftUI

/// General · Age Rating · Accessibility · App Privacy · App Review · Export
/// Compliance, as a list with selection, with the note that edits go
/// through Review & Push except App Privacy's.
struct AppInformationPageColumn: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        List(selection: selection) {
            ForEach(AppInformationPage.allCases) { page in
                AppInformationPageRow(
                    page: page,
                    status: viewModel.status(for: page),
                    hasPendingChanges: viewModel.hasPendingChanges(on: page)
                )
                .tag(page)
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            Text("Edits here go through Review & Push. App Privacy is the exception: the API can’t write it, so it’s never pushed.")
                .font(.caption2)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.large)
                .padding(.bottom, Spacing.medium)
        }
        .frame(width: 180)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("App Information pages"))
        .accessibilityIdentifier("appInformation.pageColumn")
    }

    private var selection: Binding<AppInformationPage?> {
        Binding(get: { viewModel.page }, set: { page in if let page { viewModel.page = page } })
    }
}
