//
//  AppInformationContentView.swift
//  AppLocalizer
//

import SwiftUI

/// The page column and the chosen page, with the accessibility editor
/// sheet and the toast.
struct AppInformationContentView: View {
    @Bindable var viewModel: AppInformationViewModel

    var body: some View {
        HStack(spacing: 0) {
            AppInformationPageColumn(viewModel: viewModel)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    refreshBanner
                    page
                }
                .padding(.horizontal, Spacing.xxLarge - 4)
                .padding(.vertical, Spacing.large + 2)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("appInformation.page")
        }
        .background(Palette.content)
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                AppInformationToast(text: toast) { viewModel.toast = nil }
                    .padding(.bottom, Spacing.large)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.toast)
        .sheet(item: $viewModel.editor) { item in
            AccessibilityEditorSheet(viewModel: viewModel, draft: viewModel.editor ?? item)
        }
    }

    @ViewBuilder
    private var page: some View {
        switch viewModel.page {
        case .accessibility: AccessibilityPageView(viewModel: viewModel)
        case .appPrivacy: AppPrivacyPageView()
        case .general, .ageRating, .appReview, .exportCompliance:
            if viewModel.isLoaded {
                loadedPage
            } else if let message = viewModel.errorMessage {
                AppInformationLoadErrorView(message: message) {
                    Task { await viewModel.loadContent() }
                }
            } else {
                AppInformationPageSkeleton()
            }
        }
    }

    @ViewBuilder
    private var loadedPage: some View {
        switch viewModel.page {
        case .general: GeneralPageView(viewModel: viewModel)
        case .ageRating: AgeRatingPageView(viewModel: viewModel)
        case .appReview: AppReviewPageView(viewModel: viewModel)
        case .exportCompliance: ExportCompliancePageView(viewModel: viewModel)
        case .accessibility, .appPrivacy: EmptyView()
        }
    }

    /// A reload failed after the pages had loaded: they stay, with why.
    @ViewBuilder
    private var refreshBanner: some View {
        if viewModel.isLoaded, let message = viewModel.errorMessage, viewModel.page != .accessibility, viewModel.page != .appPrivacy {
            Banner(kind: .apiError, title: String(localized: "Couldn’t refresh app information"), message: message) {
                Button(String(localized: "Try Again")) {
                    Task { await viewModel.loadContent() }
                }
            }
            .padding(.horizontal, -Spacing.large)
            .accessibilityIdentifier("appInformation.refreshError")
        }
    }
}
