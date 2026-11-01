//
//  AppListViewModel.swift
//  AppLocalizer
//

import Foundation
import Observation

/// The app library in the sidebar: loads the account's apps and their
/// icons, filters them with the search field, sorts them and keeps the
/// selection, which picks the app the workspace shows.
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
    /// The icons found so far, so a reload keeps showing them.
    private var iconURLs: [StoreApp.ID: URL] = [:]

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
            apps = try await services.apps().map { app in
                var app = app
                if app.icon == nil, let url = iconURLs[app.id] { app.icon = .remote(url) }
                return app
            }
            lastSyncedAt = .now
            if selectedApp == nil { selectedAppID = apps.first?.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fills in the icons of the apps that still draw a letter, from each
    /// one's latest build, one app at a time like the summaries. An app
    /// whose request fails keeps its letter until the next load.
    func loadIcons() async {
        for id in apps.filter({ $0.icon == nil }).map(\.id) {
            guard !Task.isCancelled else { return }
            guard let url = try? await services.iconURL(appID: id) else { continue }
            iconURLs[id] = url
            if let index = apps.firstIndex(where: { $0.id == id }), apps[index].icon == nil {
                apps[index].icon = .remote(url)
            }
        }
    }

    /// The team's name from App Store Connect, or nil when the key's role
    /// can't read it or the team has no certificates.
    func findTeamName() async -> String? {
        try? await services.teamName()
    }
}
