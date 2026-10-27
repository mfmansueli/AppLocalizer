//
//  ScreenshotBackupStoreTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Replaced screenshots kept on this Mac: one folder per push with a
/// `backup.json`, files by locale, display type and position.
@MainActor
@Suite("ScreenshotBackupStore")
struct ScreenshotBackupStoreTests {
    private let date = Date(timeIntervalSince1970: 1_791_815_525)

    private func image(
        _ locale: String,
        _ display: ScreenshotDisplayType = .iPhone,
        position: Int,
        backupID: String = "2026-10-12-143205"
    ) -> ScreenshotBackupImage {
        ScreenshotBackupImage(
            backupID: backupID, locale: locale, displayType: display, position: position, liveID: "live-\(locale)-\(position)",
            fileName: "\(locale)-\(position).png", checksum: "c\(position)", pixelSize: PixelSize(width: 1320, height: 2868), origin: .uploadedByHand
        )
    }

    private func temporaryRoot() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "ScreenshotBackupStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    @Test func filesAreKeptInTheBackupsFolderWithAnIndex() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = FileScreenshotBackupStore(root: root)
        let german = image("de-DE", position: 2)
        try store.keep(Data("png".utf8), as: german, appID: "app1", date: date)
        try store.keep(Data("ipad".utf8), as: image("de-DE", .iPad, position: 0), appID: "app1", date: date)

        let folder = root.appending(path: "app1/2026-10-12-143205", directoryHint: .isDirectory)
        #expect(FileManager.default.fileExists(atPath: folder.appending(path: "backup.json").path()))
        #expect(FileManager.default.fileExists(atPath: folder.appending(path: "de-DE/APP_IPHONE_67/3.png").path()))
        let backup = try #require(store.backup(id: "2026-10-12-143205", appID: "app1"))
        #expect(backup.date == date)
        #expect(backup.images.count == 2)
        #expect(backup.images(locale: "de-DE").map(\.displayType) == [.iPhone, .iPad])
        #expect(try store.data(for: german, appID: "app1") == Data("png".utf8))
    }

    @Test func keepingTheSamePositionAgainReplacesIt() throws {
        let root = temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = FileScreenshotBackupStore(root: root)
        try store.keep(Data("one".utf8), as: image("ja", position: 0), appID: "app1", date: date)
        try store.keep(Data("two".utf8), as: image("ja", position: 0), appID: "app1", date: date)
        let backup = try #require(store.backup(id: "2026-10-12-143205", appID: "app1"))
        #expect(backup.images.count == 1)
        #expect(try store.data(for: backup.images[0], appID: "app1") == Data("two".utf8))
    }

    @Test func anotherAppsOrPushsBackupIsSeparate() throws {
        let store = InMemoryScreenshotBackupStore()
        try store.keep(Data("a".utf8), as: image("de-DE", position: 0), appID: "app1", date: date)
        try store.keep(Data("b".utf8), as: image("de-DE", position: 0, backupID: "later"), appID: "app1", date: date)
        #expect(store.backup(id: "2026-10-12-143205", appID: "app2") == nil)
        #expect(store.backup(id: "later", appID: "app1")?.images.count == 1)
        #expect(throws: (any Error).self) { try store.data(for: image("fr-FR", position: 0), appID: "app1") }
    }

    @Test func backupIDsComeFromThePushsDate() {
        let date = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10, day: 12, hour: 14, minute: 32, second: 5).date
        #expect(date.map(ScreenshotBackup.id(for:)) == "2026-10-12-143205")
    }

    @Test func localesAreListedInTheOrderTheyWereKept() {
        var backup = ScreenshotBackup(id: "b", appID: "a", date: date, images: [])
        backup.add(image("ja", position: 0))
        backup.add(image("de-DE", position: 0))
        backup.add(image("ja", position: 1))
        #expect(backup.locales == ["ja", "de-DE"])
        #expect(backup.images(locale: "ja", displayType: .iPhone).map(\.position) == [0, 1])
    }
}
