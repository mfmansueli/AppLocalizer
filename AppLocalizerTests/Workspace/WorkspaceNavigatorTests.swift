//
//  WorkspaceNavigatorTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("WorkspaceNavigator")
struct WorkspaceNavigatorTests {
    @Test func openSwitchesSectionAndLeavesTheIntent() {
        let navigator = WorkspaceNavigator()
        #expect(navigator.section == .overview)
        navigator.open(.storePage, intent: .translateMissing)
        #expect(navigator.section == .storePage)
        #expect(navigator.intent == .translateMissing)
    }

    @Test func consumingClearsOnlyTheMatchingIntent() {
        let navigator = WorkspaceNavigator()
        navigator.send(.search)
        navigator.consume(.translateMissing)
        #expect(navigator.intent == .search)
        navigator.consume(.search)
        #expect(navigator.intent == nil)
    }

    @Test func refreshBumpsTheCounter() {
        let navigator = WorkspaceNavigator()
        navigator.refresh()
        navigator.refresh()
        #expect(navigator.refreshCount == 2)
    }

    @Test func reviewingProposalsFiltersToTheAssistantUntilClosed() {
        let navigator = WorkspaceNavigator()
        navigator.reviewProposals(from: "Claude Code")
        #expect(navigator.isReviewPresented)
        #expect(navigator.reviewSourceFilter == .assistant("Claude Code"))
        navigator.reviewDidClose()
        #expect(navigator.reviewSourceFilter == nil)
    }

    @Test func reviewingWithoutAnAssistantShowsEveryChange() {
        let navigator = WorkspaceNavigator()
        navigator.reviewProposals(from: nil)
        #expect(navigator.isReviewPresented)
        #expect(navigator.reviewSourceFilter == nil)
    }

    @Test func openingAnotherAppsSectionAsksToSelectIt() {
        let navigator = WorkspaceNavigator()
        navigator.open(.storePage, intent: .showScreenshots, appID: "2")
        #expect(navigator.requestedAppID == "2")
        #expect(navigator.intent == .showScreenshots)
        navigator.consumeAppRequest()
        #expect(navigator.requestedAppID == nil)
        #expect(navigator.intent == .showScreenshots)
    }

    @Test func onlyTheViewThatHidTheSidebarShowsItAgain() {
        let navigator = WorkspaceNavigator()
        let leaving = UUID()
        let arriving = UUID()
        navigator.hideSidebar(true, for: leaving)
        navigator.hideSidebar(true, for: arriving)
        navigator.hideSidebar(false, for: leaving)
        #expect(navigator.hidesSidebar)
        navigator.hideSidebar(false, for: arriving)
        #expect(!navigator.hidesSidebar)
    }

    @Test func sectionsMapToCommandDigits() {
        #expect(AppWorkspaceSection.allCases.map(\.shortcutDigit) == ["1", "2", "3", "4"])
    }
}
