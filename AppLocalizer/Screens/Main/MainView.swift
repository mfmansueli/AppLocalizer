//
//  MainView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window once an API key is connected: the app library in the
/// sidebar, the selected app's workspace in the detail column.
struct MainView: View {
    @State private var viewModel: AppListViewModel
    @State private var section: AppWorkspaceSection = .subscriptionPricing

    init(credentials: AppStoreConnectCredentials) {
        let client = AppStoreConnectClient(credentials: credentials)
        self.init(viewModel: AppListViewModel(services: LiveAppListServices(client: client)))
    }

    /// With an existing model — DEBUG scenes and previews.
    init(viewModel: AppListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            AppSidebar(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            if let app = viewModel.selectedApp {
                AppWorkspaceView(app: app, section: $section)
            } else if !viewModel.apps.isEmpty {
                ContentUnavailableView("Select an app", systemImage: "sidebar.left", description: Text("Pick an app in the sidebar to localize it."))
            }
        }
        .task { await viewModel.load() }
    }
}
