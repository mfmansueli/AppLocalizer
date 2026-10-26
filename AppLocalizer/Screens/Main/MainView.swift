//
//  MainView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window once an API key is connected: the app library in the
/// sidebar, the selected app's workspace in the detail column, and the
/// Review & Push and Activity sheets. Right after a key is connected it
/// shows "Loading your apps…" until the first sync is done.
struct MainView: View {
    @State private var viewModel: AppListViewModel
    @State private var summaries: AppSummaryStore
    @State private var navigator: WorkspaceNavigator
    @State private var isSyncing: Bool
    private let services: WorkspaceServices
    private let accounts: [TeamAccount]
    private let currentAccountID: TeamAccount.ID?
    private let onSelectAccount: (TeamAccount) -> Void
    private let onAddKey: () -> Void
    private let onFirstSyncFinished: () -> Void

    @Environment(ChangeQueue.self) private var changes
    @Environment(PushController.self) private var push
    @Environment(AppPreferences.self) private var preferences
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(MCPServerController.self) private var assistants
    @Environment(TranslationPreferences.self) private var translation

    init(
        credentials: AppStoreConnectCredentials,
        accounts: [TeamAccount],
        isFirstSync: Bool = false,
        onSelectAccount: @escaping (TeamAccount) -> Void = { _ in },
        onAddKey: @escaping () -> Void = {},
        onFirstSyncFinished: @escaping () -> Void = {}
    ) {
        self.init(
            services: .live(client: AppStoreConnectClient(credentials: credentials)),
            accounts: accounts,
            currentAccountID: credentials.keyID,
            isFirstSync: isFirstSync,
            onSelectAccount: onSelectAccount,
            onAddKey: onAddKey,
            onFirstSyncFinished: onFirstSyncFinished
        )
    }

    /// With existing services — DEBUG scenes and previews.
    init(
        services: WorkspaceServices,
        accounts: [TeamAccount] = [],
        currentAccountID: TeamAccount.ID? = nil,
        selectedAppID: StoreApp.ID? = nil,
        section: AppWorkspaceSection = .overview,
        presentedSheet: WorkspaceSheet? = nil,
        isFirstSync: Bool = false,
        onSelectAccount: @escaping (TeamAccount) -> Void = { _ in },
        onAddKey: @escaping () -> Void = {},
        onFirstSyncFinished: @escaping () -> Void = {}
    ) {
        self.services = services
        self.accounts = accounts
        self.currentAccountID = currentAccountID
        self.onSelectAccount = onSelectAccount
        self.onAddKey = onAddKey
        self.onFirstSyncFinished = onFirstSyncFinished
        _isSyncing = State(initialValue: isFirstSync)
        _viewModel = State(initialValue: AppListViewModel(services: services.appList, selectedAppID: selectedAppID))
        _summaries = State(initialValue: AppSummaryStore(services: services))
        let navigator = WorkspaceNavigator(section: section)
        switch presentedSheet {
        case .review: navigator.isReviewPresented = true
        case let .proposals(client): navigator.reviewProposals(from: client)
        case .activity: navigator.isActivityPresented = true
        case nil: break
        }
        _navigator = State(initialValue: navigator)
    }

    var body: some View {
        content
            .sheet(isPresented: $navigator.isReviewPresented, onDismiss: navigator.reviewDidClose) {
                ReviewPushSheet(viewModel: reviewViewModel())
            }
            .sheet(isPresented: $navigator.isActivityPresented, onDismiss: navigator.activityDidClose) {
                ActivitySheet()
            }
            .task { configurePush() }
            .task { attachAssistants() }
            .onDisappear { assistants.workspace = nil }
            .task { await loadLibrary() }
            .onChange(of: navigator.refreshCount) {
                summaries.invalidateAll()
                Task { await loadLibrary() }
            }
            // Outermost, so the sheets see them too.
            .environment(navigator)
            .environment(summaries)
            .focusedSceneValue(\.workspaceNavigator, isSyncing ? nil : navigator)
    }

    @ViewBuilder
    private var content: some View {
        if isSyncing {
            FirstSyncView(progress: FirstSyncProgress(
                appCount: viewModel.hasLoaded ? viewModel.apps.count : nil,
                syncedCount: viewModel.apps.count { summaries.isSettled($0.id) }
            ))
        } else {
            library
        }
    }

    private var library: some View {
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
    }

    @ViewBuilder
    private var detail: some View {
        if let app = viewModel.selectedApp {
            AppWorkspaceView(app: app, library: viewModel.apps.map(\.id), services: services)
                .id(app.id)
        } else if viewModel.isLoading, viewModel.apps.isEmpty {
            OverviewSkeleton()
                .padding(Spacing.xxLarge)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else if !viewModel.apps.isEmpty {
            ContentUnavailableView("Select an app", systemImage: "sidebar.left", description: Text("Pick an app in the sidebar to localize it."))
        }
    }

    /// Review & Push for the selected app, or for every app's proposals
    /// from one assistant when the toolbar indicator opened it.
    private func reviewViewModel() -> ReviewPushViewModel {
        let review = ReviewPushViewModel(
            queue: changes,
            push: push,
            selectedAppID: viewModel.selectedAppID,
            appName: appName,
            pushConfirmation: preferences.pushConfirmation,
            confirmsPriceIncreases: preferences.confirmsPriceIncreases
        )
        if let filter = navigator.reviewSourceFilter {
            review.scope = .allApps
            review.sourceFilter = filter
        }
        return review
    }

    private func appName(_ id: StoreApp.ID) -> String {
        viewModel.apps.first { $0.id == id }?.name ?? id
    }

    /// Points Review & Push at this account and reloads what a push changed.
    private func configurePush() {
        push.transport = services.push
        push.appName = { [viewModel] id in viewModel.apps.first { $0.id == id }?.name ?? id }
        push.onPushed = { [summaries, navigator] appIDs in
            for appID in appIDs {
                summaries.invalidate(appID)
            }
            navigator.refresh()
        }
    }

    /// Lets connected assistants read and propose for this account.
    private func attachAssistants() {
        let teamName = accounts.first { $0.id == currentAccountID }?.name ?? String(localized: "This account")
        assistants.workspace = MCPWorkspace(
            teamName: teamName,
            services: services,
            changes: changes,
            pricingModes: pricingModes,
            apps: { [viewModel] in
                if !viewModel.hasLoaded { await viewModel.load() }
                if let message = viewModel.errorMessage, viewModel.apps.isEmpty { throw MCPToolError.unavailable(message) }
                return viewModel.apps
            },
            glossary: { [translation] in translation.glossary },
            commission: { [preferences] in Commission(preferenceRate: preferences.commissionRate) }
        )
    }

    private func loadLibrary() async {
        await viewModel.load()
        await summaries.prefetch(viewModel.apps)
        if isSyncing, !Task.isCancelled {
            isSyncing = false
            onFirstSyncFinished()
        }
    }
}
