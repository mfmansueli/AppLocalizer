//
//  AppSidebar.swift
//  AppLocalizer
//

import SwiftUI

/// The app library column: the account's apps with search, plus the
/// loading, empty and error states.
struct AppSidebar: View {
    @Bindable var viewModel: AppListViewModel

    var body: some View {
        List(selection: $viewModel.selectedAppID) {
            Section("Apps") {
                ForEach(viewModel.visibleApps) { app in
                    AppRow(app: app)
                        .tag(app.id)
                        .accessibilityIdentifier("sidebar.app.\(app.id)")
                }
            }
        }
        .accessibilityIdentifier("sidebar.appList")
        .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "Name, bundle ID or SKU")
        .overlay { state }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await viewModel.load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r")
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("sidebar.refreshButton")
            }
        }
    }

    @ViewBuilder
    private var state: some View {
        if viewModel.isLoading, viewModel.apps.isEmpty {
            ProgressView("Loading apps…")
        } else if let message = viewModel.errorMessage, viewModel.apps.isEmpty {
            ContentUnavailableView {
                Label("Couldn't load apps", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
                    .accessibilityIdentifier("sidebar.errorMessage")
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .accessibilityIdentifier("sidebar.retryButton")
            }
        } else if viewModel.hasLoaded, viewModel.apps.isEmpty {
            ContentUnavailableView(
                "No apps",
                systemImage: "square.dashed",
                description: Text("This team doesn't have any apps in App Store Connect yet.")
            )
        } else if !viewModel.searchText.isEmpty, viewModel.visibleApps.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        }
    }
}
