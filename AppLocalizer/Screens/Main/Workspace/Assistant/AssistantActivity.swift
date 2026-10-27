//
//  AssistantActivity.swift
//  AppLocalizer
//

import Foundation

/// What the toolbar's assistant indicator shows: the assistant working right
/// now, or how many assistant proposals wait, per app: in review, and
/// screenshot proposals waiting in their own sheet. Quiet when there's
/// neither, so the toolbar only changes while assistants matter.
struct AssistantActivity: Hashable {
    /// One app's waiting proposals.
    struct AppProposals: Hashable, Identifiable {
        var appID: StoreApp.ID
        var count: Int
        var id: StoreApp.ID { appID }
    }

    /// The assistant that's working, e.g. "Claude Code"; nil when none is.
    var workingClient: String?
    /// Apps with waiting proposals, most first.
    var apps: [AppProposals]
    /// What the popover lists: `apps`, then other apps in the library with
    /// none, up to `rowLimit` rows in all.
    var rows: [AppProposals]
    /// The assistant with the most waiting proposals.
    var leadingClient: String?
    /// Proposals waiting in Review & Push, of all apps.
    var reviewCount: Int
    /// The assistant with the most proposals in Review & Push.
    var leadingReviewClient: String?
    /// Apps with screenshot proposals waiting, most first.
    var screenshotApps: [AppProposals]
    /// The Proposals sheet is open: the indicator stays while it is.
    var keepsVisible: Bool

    /// Apps with nothing waiting fill the popover up to this many rows.
    static let rowLimit = 3

    /// `changes` is the whole review queue; a change counts when an
    /// assistant proposed it, or proposed an alternative to the person's.
    /// `library` is every app in the library, in its order.
    /// `screenshotProposals` is, per app, the assistant of each screenshot
    /// proposal waiting.
    init(
        workingClient: String?,
        changes: [PendingChange],
        library: [StoreApp.ID] = [],
        screenshotProposals: [StoreApp.ID: [String]],
        keepsVisible: Bool = false
    ) {
        self.workingClient = workingClient
        self.keepsVisible = keepsVisible
        var perApp: [StoreApp.ID: Int] = [:]
        var perClient: [String: Int] = [:]
        var reviewClients: [String: Int] = [:]
        for change in changes {
            let source = change.source.isAssistant ? change.source : change.alternative?.source
            guard case let .assistant(client) = source else { continue }
            perApp[change.appID, default: 0] += 1
            perClient[client, default: 0] += 1
            reviewClients[client, default: 0] += 1
        }
        reviewCount = reviewClients.values.reduce(0, +)
        for (appID, clients) in screenshotProposals {
            perApp[appID, default: 0] += clients.count
            clients.forEach { perClient[$0, default: 0] += 1 }
        }
        apps = Self.sorted(perApp)
        screenshotApps = Self.sorted(screenshotProposals.mapValues(\.count).filter { $0.value > 0 })
        let quiet = library.filter { perApp[$0] == nil }.prefix(max(0, Self.rowLimit - apps.count))
        rows = apps + quiet.map { AppProposals(appID: $0, count: 0) }
        leadingClient = Self.leading(perClient)
        leadingReviewClient = Self.leading(reviewClients)
    }

    /// Counts screenshot proposals from the shared document center, and
    /// stays visible while its Proposals sheet is open.
    @MainActor
    init(workingClient: String?, changes: [PendingChange], library: [StoreApp.ID] = []) {
        let center = ScreenshotsDocumentCenter.shared
        self.init(
            workingClient: workingClient, changes: changes, library: library,
            screenshotProposals: center.waitingClients(in: library), keepsVisible: center.presentedProposals != nil
        )
    }

    private static func sorted(_ counts: [StoreApp.ID: Int]) -> [AppProposals] {
        counts.map { AppProposals(appID: $0.key, count: $0.value) }.sorted { ($0.count, $1.appID) > ($1.count, $0.appID) }
    }

    private static func leading(_ counts: [String: Int]) -> String? {
        counts.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }

    var proposalCount: Int { apps.reduce(0) { $0 + $1.count } }
    var isWorking: Bool { workingClient != nil }
    var isVisible: Bool { isWorking || proposalCount > 0 || keepsVisible }
    var hasScreenshotProposals: Bool { !screenshotApps.isEmpty }

    /// The assistant the indicator names and tags.
    var client: String? { workingClient ?? leadingClient }

    /// "Claude Code" while it works, else "2 proposals".
    var title: String {
        if let workingClient { return workingClient }
        return Self.proposalsText(proposalCount)
    }

    /// What VoiceOver says: "Claude Code is proposing changes" or "2
    /// proposals waiting for review".
    var accessibilityLabel: String {
        if let workingClient { return String(localized: "\(workingClient) is proposing changes") }
        return proposalCount == 1
            ? String(localized: "1 proposal waiting for review")
            : String(localized: "\(proposalCount) proposals waiting for review")
    }

    static func proposalsText(_ count: Int) -> String {
        switch count {
        case 0: String(localized: "None")
        case 1: String(localized: "1 proposal")
        default: String(localized: "\(count) proposals")
        }
    }
}
