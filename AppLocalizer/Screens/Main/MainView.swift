//
//  MainView.swift
//  AppLocalizer
//

import SwiftUI

/// The main window once an API key is connected: the app library in the
/// sidebar, the selected app's workspace in the detail column, and the
/// Review & Push and Activity sheets. Right after a key is connected it
/// shows "Loading your apps…" until the first sync is done. It asks App
/// Store Connect for the team's name once, for the account switcher.
struct MainView: View {
    @State private var viewModel: AppListViewModel
    @State private var summaries: AppSummaryStore
    @State private var navigator: WorkspaceNavigator
    @State private var sectionModels = WorkspaceSectionModels()
    @State private var isSyncing: Bool
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    private let services: WorkspaceServices
    private let accounts: [TeamAccount]
    private let currentAccountID: TeamAccount.ID?
    private let onSelectAccount: (TeamAccount) -> Void
    private let onAddKey: () -> Void
    private let onFirstSyncFinished: () -> Void
    private let onTeamNameFound: (String) -> Void

    @Environment(ChangeQueue.self) private var changes
    @Environment(PushController.self) private var push
    @Environment(AppPreferences.self) private var preferences
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(MCPServerController.self) private var assistants
    @Environment(KeyAssistantController.self) private var keyAssistant
    @Environment(TranslationPreferences.self) private var translation
    @Environment(FieldSuggestionStore.self) private var suggestions
    @Environment(ClaudeCodeLauncher.self) private var launcher
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    init(
        credentials: AppStoreConnectCredentials,
        accounts: [TeamAccount],
        isFirstSync: Bool = false,
        onSelectAccount: @escaping (TeamAccount) -> Void = { _ in },
        onAddKey: @escaping () -> Void = {},
        onFirstSyncFinished: @escaping () -> Void = {},
        onTeamNameFound: @escaping (String) -> Void = { _ in }
    ) {
        self.init(
            services: .live(client: AppStoreConnectClient(credentials: credentials)),
            accounts: accounts,
            currentAccountID: credentials.keyID,
            isFirstSync: isFirstSync,
            onSelectAccount: onSelectAccount,
            onAddKey: onAddKey,
            onFirstSyncFinished: onFirstSyncFinished,
            onTeamNameFound: onTeamNameFound
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
        onFirstSyncFinished: @escaping () -> Void = {},
        onTeamNameFound: @escaping (String) -> Void = { _ in }
    ) {
        self.services = services
        self.accounts = accounts
        self.currentAccountID = currentAccountID
        self.onSelectAccount = onSelectAccount
        self.onAddKey = onAddKey
        self.onFirstSyncFinished = onFirstSyncFinished
        self.onTeamNameFound = onTeamNameFound
        _isSyncing = State(initialValue: isFirstSync)
        _viewModel = State(initialValue: AppListViewModel(services: services.appList, selectedAppID: selectedAppID))
        _summaries = State(initialValue: AppSummaryStore(services: services))
        let navigator = WorkspaceNavigator(section: section)
        switch presentedSheet {
        case .review: navigator.isReviewPresented = true
        case let .proposals(client): navigator.reviewProposals(from: client)
        case .activity: navigator.isActivityPresented = true
        case .assistantSetup: navigator.isAssistantSetupPresented = true
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
            .sheet(isPresented: $navigator.isAssistantSetupPresented, onDismiss: assistantSetupDidClose, content: {
                AssistantSetupSheet(
                    assistants: assistants,
                    keyAssistant: keyAssistant,
                    appName: viewModel.selectedApp?.name ?? String(localized: "your app"),
                    appID: viewModel.selectedApp?.id,
                    launcher: launcher,
                    method: navigator.assistantSetupMethod,
                    reason: navigator.setupStartsSuggestEverything ? AssistantSetupSheet.suggestEverythingReason : nil
                )
            })
            // Show Output, for runs AppLocalizer started from any screen.
            .sheet(item: shownRun) { run in
                ClaudeCodeRunOutputSheet(runID: run.id)
            }
            // The paywall, from whatever needed Pro or the toolbar's button.
            .sheet(item: Binding(get: { pro?.paywall }, set: { pro?.paywall = $0 })) { model in
                PaywallSheet(model: model) { continues in pro?.finish(model, continues: continues) }
            }
            // Free works on one app: another opens the paywall and the
            // selection stays where it was.
            .onChange(of: viewModel.selectedAppID) { old, new in
                guard let pro, let new, !pro.mayOpen(appID: new) else { return }
                viewModel.selectedAppID = old
                pro.require(.secondApp) { viewModel.selectedAppID = new }
            }
            .task { configurePush() }
            .task { attachAssistants() }
            .onDisappear { assistants.workspace = nil }
            .task { await loadLibrary() }
            .task {
                if let name = await viewModel.findTeamName() { onTeamNameFound(name) }
            }
            .onChange(of: navigator.hidesSidebar) {
                columnVisibility = navigator.hidesSidebar ? .detailOnly : .all
            }
            .onChange(of: navigator.requestedAppID) {
                guard let appID = navigator.requestedAppID else { return }
                viewModel.selectedAppID = appID
                navigator.consumeAppRequest()
            }
            .onChange(of: navigator.refreshCount) {
                summaries.invalidateAll()
                Task { await loadLibrary() }
            }
            // Outermost, so the sheets see them too.
            .environment(navigator)
            .environment(summaries)
            .environment(sectionModels)
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
        NavigationSplitView(columnVisibility: $columnVisibility) {
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
        push.screenshots.attach(ScreenshotPushWorkspace(teamName: teamName, services: services, apps: loadedApps))
    }

    /// Setup opened from Suggest Everything… that ends with an assistant
    /// connected offers to start it.
    private func assistantSetupDidClose() {
        navigator.assistantSetupMethod = nil
        guard navigator.setupStartsSuggestEverything else { return }
        navigator.setupStartsSuggestEverything = false
        if case let .connected(client) = assistants.assistantStatus {
            navigator.toast = .connected(client)
        }
    }

    /// Lets connected assistants read and propose for this account, and
    /// the toolbar open any app's screenshot proposals.
    private func attachAssistants() {
        // So a project folder that builds another app is asked about.
        launcher.bundleIDLookup = { [viewModel] appID in viewModel.apps.first { $0.id == appID }?.bundleID }
        services.screenshots.documentCenter?.librarySource = { [viewModel, services] appID in
            guard let app = viewModel.apps.first(where: { $0.id == appID }),
                  let primaryLocale = app.primaryLocale.flatMap(StoreLocaleCatalog.locale(code:)) ?? StoreLocaleCatalog.locale(code: "en-US")
            else { return nil }
            return ScreenshotsDocumentCenter.Source(app: app, services: services.screenshots, primaryLocale: primaryLocale)
        }
        assistants.workspace = MCPWorkspace(
            teamName: teamName,
            services: services,
            changes: changes,
            pricingModes: pricingModes,
            apps: loadedApps,
            glossary: { [translation] in translation.glossary },
            commission: { [preferences] in Commission(preferenceRate: preferences.commissionRate) },
            suggestions: suggestions
        )
    }

    private var teamName: String {
        accounts.first { $0.id == currentAccountID }?.name ?? String(localized: "This account")
    }

    /// The library, loading it first when the sidebar hasn't yet.
    private var loadedApps: @MainActor () async throws -> [StoreApp] {
        { [viewModel] in
            if !viewModel.hasLoaded { await viewModel.load() }
            if let message = viewModel.errorMessage, viewModel.apps.isEmpty { throw MCPToolError.unavailable(message) }
            return viewModel.apps
        }
    }

    /// The run Show Output shows, as the sheet's item.
    private var shownRun: Binding<ShownRun?> {
        Binding { launcher.shownRunID.map(ShownRun.init) } set: { launcher.shownRunID = $0?.id }
    }

    private struct ShownRun: Identifiable {
        let id: ClaudeCodeRun.ID
    }

    /// The apps, then their summaries and, alongside, their icons: one
    /// request per app that doesn't hold up the first sync.
    private func loadLibrary() async {
        let viewModel = viewModel
        await viewModel.load()
        async let icons: Void = viewModel.loadIcons()
        await summaries.prefetch(viewModel.apps)
        if isSyncing, !Task.isCancelled {
            isSyncing = false
            onFirstSyncFinished()
        }
        await icons
    }
}
