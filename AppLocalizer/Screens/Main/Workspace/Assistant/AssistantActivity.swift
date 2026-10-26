//
//  AssistantActivity.swift
//  AppLocalizer
//

import Foundation

/// What the toolbar's assistant indicator shows: the assistant working right
/// now, or how many assistant proposals wait in review, per app. Quiet when
/// there's neither, so the toolbar only changes while assistants matter.
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
    /// The assistant with the most waiting proposals.
    var leadingClient: String?

    /// `changes` is the whole review queue; a change counts when an
    /// assistant proposed it, or proposed an alternative to the person's.
    init(workingClient: String?, changes: [PendingChange]) {
        self.workingClient = workingClient
        var perApp: [StoreApp.ID: Int] = [:]
        var perClient: [String: Int] = [:]
        for change in changes {
            let source = change.source.isAssistant ? change.source : change.alternative?.source
            guard case let .assistant(client) = source else { continue }
            perApp[change.appID, default: 0] += 1
            perClient[client, default: 0] += 1
        }
        apps = perApp.map { AppProposals(appID: $0.key, count: $0.value) }
            .sorted { ($0.count, $1.appID) > ($1.count, $0.appID) }
        leadingClient = perClient.max { ($0.value, $1.key) < ($1.value, $0.key) }?.key
    }

    var proposalCount: Int { apps.reduce(0) { $0 + $1.count } }
    var isWorking: Bool { workingClient != nil }
    var isVisible: Bool { isWorking || proposalCount > 0 }

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
