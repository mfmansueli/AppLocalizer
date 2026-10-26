//
//  ChangeSourceTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("ChangeSource")
struct ChangeSourceTests {
    @Test func appliedSuggestionsAndRestoresCountAsYou() {
        #expect(ChangeSource.you.filter == .you)
        #expect(ChangeSource.suggestion.filter == .you)
        #expect(ChangeSource.restore.filter == .you)
        #expect(ChangeSource.machineTranslation.filter == .machineTranslation)
        #expect(ChangeSource.assistant(client: "Claude Code").filter == .assistant("Claude Code"))
    }

    @Test func tagsReadAsTheDesignShowsThem() {
        #expect(ChangeSource.suggestion.title == "Recommended")
        #expect(ChangeSource.assistant(client: "Claude Code").title == "Claude Code")
    }

    @Test func assistantsGetAMonogram() {
        #expect(ChangeSource.assistant(client: "Claude Code").monogram == "CC")
        #expect(ChangeSource.assistant(client: "cursor").monogram == "C")
        #expect(ChangeSource.you.monogram == nil)
    }

    @Test func roundTripsThroughJSON() throws {
        let sources: [ChangeSource] = [.you, .suggestion, .machineTranslation, .assistant(client: "Codex"), .restore]
        let decoded = try JSONDecoder().decode([ChangeSource].self, from: JSONEncoder().encode(sources))
        #expect(decoded == sources)
    }
}
