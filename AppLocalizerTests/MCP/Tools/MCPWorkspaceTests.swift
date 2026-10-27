//
//  MCPWorkspaceTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@MainActor
@Suite("MCPWorkspace")
struct MCPWorkspaceTests {
    private let workspace = MCPTestFixtures.workspace()

    @Test func findsAppsByAnyIdentifier() async throws {
        #expect(try await workspace.app(matching: "6450000001").name == "Lumen Journal")
        #expect(try await workspace.app(matching: "com.northpier.tempo").name == "Tempo Metronome")
        #expect(try await workspace.app(matching: "lumen-01").name == "Lumen Journal")
        #expect(try await workspace.app(matching: "  lumen journal ").name == "Lumen Journal")
        #expect(try await workspace.app(matching: "FIELDNOTE").name == "Fieldnote")
    }

    @Test func aNameMayBeTheStartOfOne() async throws {
        #expect(try await workspace.app(matching: "Lúmen").name == "Lumen Journal")
        #expect(try await workspace.app(matching: "tempo").name == "Tempo Metronome")
    }

    @Test func anAmbiguousOrUnknownNameListsTheApps() async {
        await #expect(throws: MCPToolError.self) { try await workspace.app(matching: "Field") }
        do {
            _ = try await workspace.app(matching: "Nope")
            Issue.record("Expected no match")
        } catch {
            #expect(error.localizedDescription.contains("No app matches “Nope”"))
            #expect(error.localizedDescription.contains("Lumen Journal"))
        }
    }
}
