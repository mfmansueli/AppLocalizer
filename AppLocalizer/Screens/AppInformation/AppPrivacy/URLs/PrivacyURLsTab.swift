//
//  PrivacyURLsTab.swift
//  AppLocalizer
//

import SwiftUI

/// Privacy URLs: each locale's Privacy Policy URL (required) and User
/// Privacy Choices URL (optional). Unlike the worksheet these sync: an
/// edit is a Review & Push change, and the Privacy Policy URL's is the same
/// change Store Page makes.
struct PrivacyURLsTab: View {
    let viewModel: AppPrivacyViewModel
    @Environment(WorkspaceNavigator.self) private var navigator

    var body: some View {
        Group {
            switch viewModel.urls {
            case .idle, .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(Text("Loading the privacy URLs"))
            case let .failed(message):
                AccessibilityLoadErrorView(message: message, requestLine: nil) {
                    Task { await viewModel.loadURLs() }
                }
                .padding(Spacing.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            case .loaded:
                if let table = viewModel.urlsTable {
                    content(table)
                }
            }
        }
        .task { if viewModel.urls.value == nil { await viewModel.loadURLs() } }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.urls")
    }

    private func content(_ table: PrivacyURLsTable) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Spacing.small) {
                Text(String(localized: "\(viewModel.urlsCoverageText ?? "") · app-level fields, sent through Review & Push"))
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("appInformation.appPrivacy.urls.coverage")
                Button(String(localized: "Fill Missing from \(table.content.primaryLocale.name)"), action: viewModel.fillMissingPolicyURLs)
                    .disabled(table.missingPolicyLocales.allSatisfy { $0 == table.content.primaryLocale })
                    .accessibilityIdentifier("appInformation.appPrivacy.urls.fillMissing")
                Button(String(localized: "Also in Store Page ↗")) { navigator.open(.storePage) }
                    .accessibilityIdentifier("appInformation.appPrivacy.urls.storePage")
            }
            .controlSize(.small)
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.small + 2)
            PrivacyURLsHeaderRow()
            Divider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(table.locales) { locale in
                        PrivacyURLsRow(table: table, locale: locale, viewModel: viewModel)
                        Divider()
                    }
                }
            }
        }
    }
}
