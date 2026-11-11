//
//  Entitlements.swift
//  AppLocalizer
//

import Foundation
import Observation

/// What this person may use: one type every gated button asks
/// (`canUse(_:)`) before it acts, opening the paywall with its context when
/// the answer is no. Nothing is hidden in Free, and nothing a person
/// already made is ever locked: only the all-at-once actions, Autopilot,
/// recommended prices, Retention, a second app and the extra templates.
@MainActor
@Observable
final class Entitlements {
    private(set) var status: ProStatus = .free
    /// The plans with this person's prices; empty until the App Store
    /// answers.
    private(set) var offers: [ProOffer] = []
    private(set) var isLoadingOffers = false

    @ObservationIgnored private let store: any ProStore
    @ObservationIgnored private var updates: Task<Void, Never>?
    /// DEBUG builds and tests: Pro without a purchase, or Free whatever
    /// was bought. Nil follows the App Store.
    var override: Bool?

    /// Free's apps and App Store Connect accounts.
    static let freeAppLimit = 1
    /// Free's screenshot templates, of the gallery's 14.
    static let freeTemplateLimit = 3

    init(store: any ProStore, override: Bool? = nil) {
        self.store = store
        self.override = override
    }

    var isPro: Bool { override ?? status.isPro }

    func canUse(_: ProFeature) -> Bool { isPro }

    /// At launch: what the person owns, then every change to it (a
    /// renewal, a refund, the trial ending) for as long as the app runs.
    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self, store] in
            let owned = await store.status()
            self?.status = owned
            for await status in store.statusUpdates() {
                self?.status = status
            }
        }
    }

    /// The paywall opened: the plans and their prices.
    func loadOffers() async {
        guard offers.isEmpty, !isLoadingOffers else { return }
        isLoadingOffers = true
        offers = await store.offers()
        isLoadingOffers = false
    }

    func offer(for plan: ProPlan) -> ProOffer? {
        offers.first { $0.plan == plan }
    }

    func purchase(_ plan: ProPlan) async -> ProPurchaseOutcome {
        let outcome = await store.purchase(plan)
        if case let .purchased(status) = outcome { self.status = status }
        return outcome
    }

    /// Restore Purchases: true when Pro came back.
    func restore() async -> Bool {
        status = await store.restore()
        return status.isPro
    }
}
