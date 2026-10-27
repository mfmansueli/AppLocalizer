//
//  PrivacyWorksheetStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Where worksheets are kept: a JSON file per app (in a temporary folder
/// here), read back by a new store, and in memory for tests and scenes.
@MainActor
@Suite("PrivacyWorksheetStore")
struct PrivacyWorksheetStoreTests {
    private typealias Support = PrivacyTestSupport

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "PrivacyWorksheetStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    @Test func aWorksheetIsSavedAndReadBack() {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var worksheet = Support.proposed([(.userId, Support.suggestion(Support.collected(linked: true), evidence: [Support.manifest(.userId)]))])
        worksheet.ask(Support.question(), at: Support.date)
        worksheet.finishScan(at: Support.date)
        worksheet.markPublished(at: Support.date)

        FilePrivacyWorksheetStore(directory: directory).setWorksheet(worksheet, for: "6450000001")
        #expect(FileManager.default.fileExists(atPath: directory.appending(path: "6450000001.json").path(percentEncoded: false)))
        let read = FilePrivacyWorksheetStore(directory: directory).worksheet(for: "6450000001")
        #expect(read == worksheet)
    }

    @Test func aMissingOrUnreadableFileIsAnEmptyWorksheet() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(FilePrivacyWorksheetStore(directory: directory).worksheet(for: "1") == PrivacyWorksheet())
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appending(path: "2.json"))
        #expect(FilePrivacyWorksheetStore(directory: directory).worksheet(for: "2") == PrivacyWorksheet())
    }

    @Test func anOlderFileWithFewerFieldsStillLoads() throws {
        let json = #"{"collects":{"value":true,"status":"yours"},"isStarted":true}"#
        let worksheet = try JSONDecoder().decode(PrivacyWorksheet.self, from: Data(json.utf8))
        #expect(worksheet.collects?.value == true)
        #expect(worksheet.entries.isEmpty)
        #expect(worksheet.isStarted)
    }

    @Test func theAppIDCantLeaveTheFolder() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        FilePrivacyWorksheetStore(directory: directory).setWorksheet(Support.answered([:]), for: "../escape")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
        #expect(files == ["escape.json"])
    }

    @Test func updateReadsChangesAndWritesBack() {
        let store = InMemoryPrivacyWorksheetStore()
        store.update("1") { $0.setCollects(false) }
        #expect(store.worksheet(for: "1").collects?.value == false)
        #expect(store.worksheet(for: "2") == PrivacyWorksheet())
    }
}
