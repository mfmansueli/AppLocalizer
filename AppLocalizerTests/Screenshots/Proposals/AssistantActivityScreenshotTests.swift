//
//  AssistantActivityScreenshotTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("AssistantActivity · screenshot proposals")
struct AssistantActivityScreenshotTests {
    private func change(_ id: String, app: String, client: String) -> PendingChange {
        PendingChange(
            id: id, appID: app, section: .storePage, group: "Group", title: id, oldValue: "old", newValue: "new",
            source: .assistant(client: client), requests: []
        )
    }

    @Test func screenshotProposalsCountWithTheReviewQueue() {
        let activity = AssistantActivity(
            workingClient: nil, changes: [change("a", app: "2", client: "Cursor")], library: ["1", "2", "3"],
            screenshotProposals: ["1": ["Claude Code", "Claude Code"]]
        )
        #expect(activity.isVisible)
        #expect(activity.proposalCount == 3)
        #expect(activity.title == "3 proposals")
        #expect(activity.apps.map(\.appID) == ["1", "2"])
        #expect(activity.rows.map(\.appID) == ["1", "2", "3"])
        #expect(activity.reviewCount == 1)
        #expect(activity.leadingReviewClient == "Cursor")
        #expect(activity.leadingClient == "Claude Code")
        #expect(activity.screenshotApps.map(\.appID) == ["1"])
        #expect(activity.hasScreenshotProposals)
    }

    @Test func onlyScreenshotProposalsStillShowTheIndicator() {
        let activity = AssistantActivity(workingClient: nil, changes: [], screenshotProposals: ["1": ["Claude Code"]])
        #expect(activity.isVisible)
        #expect(activity.reviewCount == 0)
        #expect(activity.title == "1 proposal")
    }

    @Test func staysWhileTheProposalsSheetIsOpen() {
        let activity = AssistantActivity(workingClient: nil, changes: [], screenshotProposals: [:], keepsVisible: true)
        #expect(activity.isVisible)
        #expect(activity.proposalCount == 0)
    }
}
