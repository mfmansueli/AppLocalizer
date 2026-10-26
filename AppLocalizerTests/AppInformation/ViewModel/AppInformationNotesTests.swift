//
//  AppInformationNotesTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What's kept on this Mac per app: round trips, and notes saved before a
/// field existed still load.
@MainActor
@Suite("AppInformationNotes")
struct AppInformationNotesTests {
    @Test func notesRoundTripAndOlderNotesStillDecode() throws {
        var notes = AppInformationNotes()
        notes.overrideReason = "Because."
        notes.exportAnswers = ExportComplianceAnswers(answers: [.usesEncryption: false])
        notes.commonTasks = ["writing an entry"]
        let decoded = try JSONDecoder().decode(AppInformationNotes.self, from: JSONEncoder().encode(notes))
        #expect(decoded == notes)

        let older = try JSONDecoder().decode(AppInformationNotes.self, from: Data(#"{"overrideReason":"Old"}"#.utf8))
        #expect(older.overrideReason == "Old")
        #expect(older.commonTasks.isEmpty)
        #expect(older.accessibilitySuggestions.isEmpty)
    }

    @Test func theInMemoryStoreKeepsNotesPerApp() {
        let store = InMemoryAppInformationNotesStore()
        var notes = AppInformationNotes()
        notes.overrideReason = "Lumen"
        store.setNotes(notes, for: "a")
        #expect(store.notes(for: "a").overrideReason == "Lumen")
        #expect(store.notes(for: "b") == AppInformationNotes())
    }
}
