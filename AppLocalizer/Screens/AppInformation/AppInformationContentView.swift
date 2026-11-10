//
//  AppInformationContentView.swift
//  AppLocalizer
//

import SwiftUI

/// The page column and the chosen page, with the accessibility editor
/// sheet and the toast. App Privacy lays out its own columns and scrolling.
struct AppInformationContentView: View {
    @Bindable var viewModel: AppInformationViewModel

    /// The window is too narrow for the preview under this.
    private static let previewMinimumWidth: CGFloat = 760

    @Environment(\.undoManager) private var undoManager
    @Environment(AppPreferences.self) private var preferences
    @Environment(WorkspaceNavigator.self) private var navigator
    @State private var width: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            AppInformationPageColumn(viewModel: viewModel)
            Divider()
            if viewModel.page == .appPrivacy {
                AppPrivacyPageView(viewModel: viewModel.privacy)
            } else {
                HStack(alignment: .top, spacing: Spacing.large) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.large) {
                            refreshBanner
                            page
                        }
                        .padding(.vertical, Spacing.large + 2)
                        .padding(.horizontal, 2)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("appInformation.page")
                    if showsPreview {
                        ScrollView {
                            AppInformationPreviewPane(viewModel: viewModel)
                                .padding(.vertical, Spacing.large + 2)
                        }
                        .scrollIndicators(.never)
                        .frame(width: 236)
                    }
                }
                .padding(.horizontal, 20)
                .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
            }
        }
        .background(Palette.content)
        .overlay(alignment: .bottom) {
            if let toast = viewModel.suggestionToast {
                ActionToast(message: toast) {
                    viewModel.undoLastSuggestionBatch()
                } onAction: {
                    viewModel.suggestionToast = nil
                    navigator.isReviewPresented = true
                } onDismiss: {
                    if viewModel.suggestionToast == toast { viewModel.suggestionToast = nil }
                }
                .padding(.bottom, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if let toast = viewModel.toast {
                AppInformationToast(text: toast) { viewModel.toast = nil }
                    .padding(.bottom, Spacing.large)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: viewModel.toast)
        .animation(.default, value: viewModel.suggestionToast)
        .onAppear { viewModel.undoManager = undoManager }
        .onChange(of: undoManager) { viewModel.undoManager = undoManager }
        .sheet(item: $viewModel.editor) { item in
            AccessibilityEditorSheet(viewModel: viewModel, draft: viewModel.editor ?? item)
        }
        .sheet(isPresented: $viewModel.isAcceptAllPresented) {
            AcceptAllSheet(selection: viewModel.acceptAllSelection()) {
                viewModel.isAcceptAllPresented = false
            } onAccept: { ids, dontAskAgain in
                viewModel.isAcceptAllPresented = false
                if dontAskAgain { preferences.acceptsAllWithoutAsking = true }
                viewModel.acceptSuggestions(ids: ids, turnedOffAsking: dontAskAgain)
            }
        }
    }

    /// Age Rating keeps its own preview beside the questions.
    private var showsPreview: Bool {
        viewModel.isLoaded && viewModel.page != .ageRating && width >= Self.previewMinimumWidth
    }

    @ViewBuilder
    private var page: some View {
        switch viewModel.page {
        case .accessibility: AccessibilityPageView(viewModel: viewModel)
        case .appPrivacy: EmptyView()
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
