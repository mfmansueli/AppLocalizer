//
//  AppSidebar.swift
//  AppLocalizer
//

import SwiftUI

/// The app library column: the account switcher, search, the account's apps
/// with their indicators and a sort menu, plus the loading, empty and error
/// states and a sync line at the bottom.
struct AppSidebar: View {
    @Bindable var viewModel: AppListViewModel
    let summaries: AppSummaryStore
    let accounts: [TeamAccount]
    let currentAccountID: TeamAccount.ID?
    var onSelectAccount: (TeamAccount) -> Void = { _ in }
    var onAddKey: () -> Void = {}

    @Environment(ChangeQueue.self) private var changes
    @Environment(PricingModeStore.self) private var pricingModes
    @Environment(FieldSuggestionStore.self) private var suggestions

    var body: some View {
        List(selection: $viewModel.selectedAppID) {
            Section {
                if showsSkeleton {
                    ForEach(0..<6, id: \.self) { _ in
                        AppRowSkeleton()
                            .selectionDisabled()
                    }
                } else {
                    ForEach(viewModel.sortedVisibleApps(indicators: indicators)) { app in
                        AppRow(app: app, indicators: indicators(app))
                            .tag(app.id)
                            .accessibilityIdentifier("sidebar.app.\(app.id)")
                    }
                }
            } header: {
                HStack {
                    Text("Apps")
                    Spacer()
                    sortMenu
                }
            }
        }
        .accessibilityIdentifier("sidebar.appList")
        .searchable(text: $viewModel.searchText, placement: .sidebar, prompt: "Name, bundle ID or SKU")
        .safeAreaInset(edge: .top, spacing: 0) {
            AccountSwitcher(accounts: accounts, currentAccountID: currentAccountID, onSelect: onSelectAccount, onAddKey: onAddKey)
                .padding(.horizontal, Spacing.small)
                .padding(.bottom, Spacing.xSmall)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer
        }
        .overlay { state }
    }

    private var showsSkeleton: Bool {
        viewModel.isLoading && viewModel.apps.isEmpty
    }

    private func indicators(_ app: StoreApp) -> AppIndicators {
        let mode = pricingModes.mode(for: app.id)
        let pricing = summaries.pricing[app.id]?.value
        let counts = SectionBadgeCounts(
            appID: app.id,
            suggestions: suggestions,
            screenshots: ScreenshotsDocumentCenter.shared,
            pricing: SectionBadgeCounts.pricingCount(appID: app.id, summaries: summaries, modes: pricingModes, changes: changes)
        )
        return AppIndicators(
            pendingChangeCount: changes.count(for: app.id),
            suggestionCount: counts.total,
            localeCount: summaries.storePage[app.id]?.value?.localeCount,
            priceSuggestionCount: mode.showsSuggestions && pricing?.sellsAnything == true ? pricing?.heldBackTerritoryCount : nil
        )
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $viewModel.sortOrder) {
                ForEach(AppSortOrder.allCases) { order in
                    Text(order.title).tag(order)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sort apps")
        .accessibilityLabel(Text("Sort apps"))
        .accessibilityIdentifier("sidebar.sortMenu")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                let suggestions = suggestionTotal
                if suggestions > 0 {
                    // Every app's together: a sample "3" read as three
                    // suggestions beside Bruma's 35 and SimProps' 1.
                    HStack(spacing: Spacing.xSmall) {
                        SuggestionBadge(count: suggestions, isSmall: true)
                        Text(suggestions == 1 ? "Suggestion to review" : "Suggestions to review")
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(suggestions == 1 ? "A purple count: 1 suggestion to review" : "A purple count: \(suggestions) suggestions to review"))
                    .accessibilityIdentifier("sidebar.legend")
                }
                // "synced 2 min. ago" moves on as time passes.
                TimelineView(.everyMinute) { context in
                    Text(footerText(now: context.date))
                }
            }
            .font(.caption)
            .foregroundStyle(Palette.label2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.small)
        }
    }

    /// Every app's purple count together; the legend shows once there's one.
    private var suggestionTotal: Int {
        viewModel.apps.reduce(0) { $0 + indicators($1).suggestionCount }
    }

    private func footerText(now: Date) -> String {
        if viewModel.isLoading, viewModel.apps.isEmpty {
            return String(localized: "Syncing with App Store Connect…")
        }
        let count = String(localized: "\(viewModel.apps.count) apps")
        guard let synced = viewModel.lastSyncedAt else { return count }
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .abbreviated
        let relative = formatter.localizedString(for: synced, relativeTo: now)
        return String(localized: "\(count) · synced \(relative)")
    }

    @ViewBuilder
    private var state: some View {
        if let message = viewModel.errorMessage, viewModel.apps.isEmpty {
            ContentUnavailableView {
                Label("Couldn't load apps", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
                    .accessibilityIdentifier("sidebar.errorMessage")
            } actions: {
                Button("Try Again") { Task { await viewModel.load() } }
                    .accessibilityIdentifier("sidebar.retryButton")
            }
        } else if viewModel.hasLoaded, !viewModel.isLoading, viewModel.apps.isEmpty {
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
