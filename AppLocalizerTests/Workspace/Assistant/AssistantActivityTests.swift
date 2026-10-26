//
//  AssistantActivityTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("AssistantActivity")
struct AssistantActivityTests {
    private func change(_ id: String, app: String = "1", source: ChangeSource = .you, alternative: ChangeSource? = nil) -> PendingChange {
        var change = PendingChange(
            id: id, appID: app, section: .storePage, group: "Group", title: id, oldValue: "old", newValue: "new", source: source, requests: []
        )
        change.alternative = alternative.map { ChangeAlternative(newValue: "theirs", source: $0, requests: []) }
        return change
    }

    @Test func quietWithoutWorkOrProposals() {
        let activity = AssistantActivity(workingClient: nil, changes: [change("a"), change("b", source: .machineTranslation)])
        #expect(!activity.isVisible)
        #expect(activity.apps.isEmpty)
        #expect(activity.client == nil)
    }

    @Test func countsAssistantProposalsAndAlternativesPerApp() {
        let activity = AssistantActivity(workingClient: nil, changes: [
            change("a", app: "1", source: .assistant(client: "Claude Code")),
            change("b", app: "2", source: .assistant(client: "Cursor")),
            change("c", app: "2", source: .you, alternative: .assistant(client: "Cursor")),
            change("d", app: "2", source: .you),
        ])
        #expect(activity.apps == [.init(appID: "2", count: 2), .init(appID: "1", count: 1)])
        #expect(activity.proposalCount == 3)
        #expect(activity.leadingClient == "Cursor")
        #expect(activity.client == "Cursor")
        #expect(activity.isVisible)
        #expect(!activity.isWorking)
        #expect(activity.title == "3 proposals")
        #expect(activity.accessibilityLabel == "3 proposals waiting for review")
    }

    @Test func aWorkingAssistantIsNamedEvenWithoutProposals() {
        let activity = AssistantActivity(workingClient: "Claude Code", changes: [change("a", source: .assistant(client: "Cursor"))])
        #expect(activity.isVisible)
        #expect(activity.isWorking)
        #expect(activity.client == "Claude Code")
        #expect(activity.title == "Claude Code")
        #expect(activity.accessibilityLabel == "Claude Code is proposing changes")
        #expect(activity.leadingClient == "Cursor")
    }

    @Test func oneProposalIsSingular() {
        let activity = AssistantActivity(workingClient: nil, changes: [change("a", source: .assistant(client: "Codex"))])
        #expect(activity.title == "1 proposal")
        #expect(activity.accessibilityLabel == "1 proposal waiting for review")
        #expect(AssistantActivity.proposalsText(0) == "None")
    }

    @Test func tiesAreBrokenByAppAndClientName() {
        let activity = AssistantActivity(workingClient: nil, changes: [
            change("a", app: "2", source: .assistant(client: "Cursor")),
            change("b", app: "1", source: .assistant(client: "Claude Code")),
        ])
        #expect(activity.apps.map(\.appID) == ["1", "2"])
        #expect(activity.leadingClient == "Claude Code")
    }
}
