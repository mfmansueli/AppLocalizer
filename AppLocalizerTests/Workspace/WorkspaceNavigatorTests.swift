//
//  WorkspaceNavigatorTests.swift
//  AppLocalizerTests
//

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

    @Test func sectionsMapToCommandDigits() {
        #expect(AppWorkspaceSection.allCases.map(\.shortcutDigit) == ["1", "2", "3", "4"])
    }
}
