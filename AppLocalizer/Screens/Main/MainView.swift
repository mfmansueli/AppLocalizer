//
//  MainView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window once an API key is connected: the app library in the
/// sidebar, the selected app's workspace in the detail column, and the
/// Review & Push and Activity sheets.
struct MainView: View {
    @State private var viewModel: AppListViewModel
    @State private var summaries: AppSummaryStore
    @State private var navigator: WorkspaceNavigator
    private let services: WorkspaceServices
    private let accounts: [TeamAccount]
    private let currentAccountID: TeamAccount.ID?
    private let onSelectAccount: (TeamAccount) -> Void
    private let onAddKey: () -> Void

    init(
        credentials: AppStoreConnectCredentials,
        accounts: [TeamAccount],
        onSelectAccount: @escaping (TeamAccount) -> Void = { _ in },
        onAddKey: @escaping () -> Void = {}
    ) {
        self.init(
            services: .live(client: AppStoreConnectClient(credentials: credentials)),
            accounts: accounts,
            currentAccountID: credentials.keyID,
            onSelectAccount: onSelectAccount,
            onAddKey: onAddKey
        )
    }

    /// With existing services — DEBUG scenes and previews.
    init(
        services: WorkspaceServices,
        accounts: [TeamAccount] = [],
        currentAccountID: TeamAccount.ID? = nil,
        selectedAppID: StoreApp.ID? = nil,
        section: AppWorkspaceSection = .overview,
        onSelectAccount: @escaping (TeamAccount) -> Void = { _ in },
        onAddKey: @escaping () -> Void = {}
    ) {
        self.services = services
        self.accounts = accounts
        self.currentAccountID = currentAccountID
        self.onSelectAccount = onSelectAccount
        self.onAddKey = onAddKey
        _viewModel = State(initialValue: AppListViewModel(services: services.appList, selectedAppID: selectedAppID))
        _summaries = State(initialValue: AppSummaryStore(services: services))
        _navigator = State(initialValue: WorkspaceNavigator(section: section))
    }

    var body: some View {
        NavigationSplitView {
            AppSidebar(
                viewModel: viewModel,
                summaries: summaries,
                accounts: accounts,
                currentAccountID: currentAccountID,
                onSelectAccount: onSelectAccount,
                onAddKey: onAddKey
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: Metrics.sidebarWidth, max: 360)
        } detail: {
            detail
        }
        .environment(navigator)
        .environment(summaries)
        .focusedSceneValue(\.workspaceNavigator, navigator)
        .sheet(isPresented: $navigator.isReviewPresented) {
            ReviewPushSheet(selectedAppID: viewModel.selectedAppID, apps: viewModel.apps)
        }
        .sheet(isPresented: $navigator.isActivityPresented) {
            ActivitySheet(apps: viewModel.apps)
        }
        .task { await loadLibrary() }
        .onChange(of: navigator.refreshCount) {
            summaries.invalidateAll()
            Task { await loadLibrary() }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let app = viewModel.selectedApp {
            AppWorkspaceView(app: app, services: services)
                .id(app.id)
        } else if viewModel.isLoading, viewModel.apps.isEmpty {
            OverviewSkeleton()
                .padding(Spacing.xxLarge)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if !viewModel.apps.isEmpty {
            ContentUnavailableView("Select an app", systemImage: "sidebar.left", description: Text("Pick an app in the sidebar to localize it."))
        }
    }

    private func loadLibrary() async {
        await viewModel.load()
        await summaries.prefetch(viewModel.apps)
    }
}
