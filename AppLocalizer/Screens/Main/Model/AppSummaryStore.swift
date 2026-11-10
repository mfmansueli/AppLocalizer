//
//  AppSummaryStore.swift
//  AppLocalizer
//

import Foundation
import Observation

/// Each app's overview numbers (pricing, store page, App Information),
/// fetched once and shared by the sidebar's row indicators and the overview
/// cards. Refresh (⌘R) and a push invalidate them.
@MainActor
@Observable
final class AppSummaryStore {
    private(set) var pricing: [StoreApp.ID: LoadState<PricingSummary>] = [:]
    private(set) var storePage: [StoreApp.ID: LoadState<StorePageSummary>] = [:]
    private(set) var appInformation: [StoreApp.ID: LoadState<AppInformationSummary>] = [:]
    /// Products with a price suggestion still open, counted by Pricing once
    /// it has read every product's prices this launch.
    private(set) var pricingSuggestionCounts: [StoreApp.ID: Int] = [:]

    private let services: WorkspaceServices

    /// What each app's Xcode project supports, for the languages the App
    /// Store page doesn't have yet.
    var appSupport: AppSupportCenter? { services.storePage.appSupport }

    init(services: WorkspaceServices) {
        self.services = services
    }

    /// Fetches whatever isn't loaded (or everything with `force`), all three
    /// summaries at once.
    func load(_ app: StoreApp, force: Bool = false) async {
        async let pricingLoad: Void = loadPricing(app, force: force)
        async let storePageLoad: Void = loadStorePage(app, force: force)
        async let informationLoad: Void = loadAppInformation(app, force: force)
        _ = await (pricingLoad, storePageLoad, informationLoad)
    }

    /// Loads every app in turn, so the sidebar's indicators fill in after the
    /// library appears. One app at a time keeps App Store Connect's hourly
    /// quota for the person's own work.
    func prefetch(_ apps: [StoreApp]) async {
        for app in apps {
            guard !Task.isCancelled else { return }
            await load(app)
        }
    }

    /// True once all three summaries of an app have loaded or failed, for
    /// the first sync's progress.
    func isSettled(_ appID: StoreApp.ID) -> Bool {
        [pricing[appID]?.isSettled, storePage[appID]?.isSettled, appInformation[appID]?.isSettled].allSatisfy { $0 == true }
    }

    /// Pricing counted the products with an open price suggestion.
    func setPricingSuggestionCount(_ count: Int, for appID: StoreApp.ID) {
        guard pricingSuggestionCounts[appID] != count else { return }
        pricingSuggestionCounts[appID] = count
    }

    /// Forgets an app's numbers, e.g. after a push changed them.
    func invalidate(_ appID: StoreApp.ID) {
        pricingSuggestionCounts[appID] = nil
        pricing[appID] = nil
        storePage[appID] = nil
        appInformation[appID] = nil
    }

    func invalidateAll() {
        pricingSuggestionCounts = [:]
        pricing = [:]
        storePage = [:]
        appInformation = [:]
    }

    private func loadPricing(_ app: StoreApp, force: Bool) async {
        guard force || needsLoad(pricing[app.id]) else { return }
        pricing[app.id] = .loading
        do {
            pricing[app.id] = try await .loaded(services.pricing.summary(for: app))
        } catch {
            pricing[app.id] = .failed(error.localizedDescription)
        }
    }

    private func loadStorePage(_ app: StoreApp, force: Bool) async {
        guard force || needsLoad(storePage[app.id]) else { return }
        storePage[app.id] = .loading
        do {
            storePage[app.id] = try await .loaded(services.storePage.summary(for: app))
        } catch {
            storePage[app.id] = .failed(error.localizedDescription)
        }
    }

    private func loadAppInformation(_ app: StoreApp, force: Bool) async {
        guard force || needsLoad(appInformation[app.id]) else { return }
        appInformation[app.id] = .loading
        do {
            appInformation[app.id] = try await .loaded(services.appInformation.summary(for: app))
        } catch {
            appInformation[app.id] = .failed(error.localizedDescription)
        }
    }

    private func needsLoad(_ state: LoadState<some Sendable>?) -> Bool {
        switch state {
        case nil, .idle, .failed: true
        case .loading, .loaded: false
        }
    }
}
