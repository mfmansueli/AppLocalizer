//
//  AppListViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The app library in the sidebar: loads the account's apps, filters them
/// with the search field, sorts them and keeps the selection, which picks
/// the app the workspace shows.
@MainActor
@Observable
final class AppListViewModel {
    private(set) var apps: [StoreApp] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// Whether a load has finished at least once, so an empty account shows
    /// "No apps" instead of a blank sidebar before the first answer.
    private(set) var hasLoaded = false
    /// When the last successful load finished, for "synced 2 min ago".
    private(set) var lastSyncedAt: Date?
    var searchText = ""
    var sortOrder: AppSortOrder = .name
    var selectedAppID: StoreApp.ID?

    private let services: any AppListServices

    init(services: any AppListServices, selectedAppID: StoreApp.ID? = nil) {
        self.services = services
        self.selectedAppID = selectedAppID
    }

    /// The apps matching the search, in the account's order.
    var visibleApps: [StoreApp] { AppSearch.filter(apps, matching: searchText) }

    /// The apps matching the search, in the sort menu's order.
    func sortedVisibleApps(indicators: (StoreApp) -> AppIndicators) -> [StoreApp] {
        AppSorter.sort(visibleApps, by: sortOrder, indicators: indicators)
    }

    var selectedApp: StoreApp? {
        apps.first { $0.id == selectedAppID }
    }

    /// First load and "Refresh" (⌘R). Keeps the selection when the app is
    /// still there, otherwise selects the first one.
    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }
        do {
            apps = try await services.apps()
            lastSyncedAt = .now
            if selectedApp == nil { selectedAppID = apps.first?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
