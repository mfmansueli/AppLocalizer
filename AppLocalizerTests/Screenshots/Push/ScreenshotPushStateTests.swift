//
//  ScreenshotPushStateTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Discards and queued restores, kept per app between launches.
@MainActor
@Suite("ScreenshotPushState")
struct ScreenshotPushStateTests {
    private func request(_ locale: String, backupID: String = "b1", positions: [Int] = [0, 1]) -> ScreenshotRestoreRequest {
        let images = positions.map { position in
            ScreenshotBackupImage(
                backupID: backupID, locale: locale, displayType: .iPhone, position: position, liveID: "l\(position)", fileName: "",
                checksum: nil, pixelSize: nil, origin: .uploadedByHand
            )
        }
        return ScreenshotRestoreRequest(locale: locale, backupID: backupID, backupDate: .now, images: images)
    }

    @Test func queueingAgainReplacesALocalesRestore() {
        var state = ScreenshotPushState()
        state.queue(request("de-DE"))
        state.queue(request("de-DE", backupID: "b2", positions: [0]))
        state.queue(request("ja"))
        #expect(state.restores.map(\.id) == ["de-DE|b2", "ja|b1"])
        #expect(state.restore(for: "de-DE")?.images.count == 1)
    }

    @Test func removingARestoreDropsItsDiscards() {
        var state = ScreenshotPushState()
        let german = request("de-DE")
        state.queue(german)
        state.keptRestores.insert(german.images[0].id)
        state.removeRestore(for: "de-DE")
        #expect(state.isEmpty)
    }

    @Test func restoresForUnpinnedLocalesArePruned() {
        var state = ScreenshotPushState()
        state.queue(request("de-DE"))
        state.queue(request("ja"))
        #expect(state.pruneRestores { $0 == "ja" })
        #expect(state.restores.map(\.locale) == ["ja"])
        #expect(!state.pruneRestores { _ in true })
    }

    @Test func theFileStoreRoundTrips() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ScreenshotPushStateTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = FileScreenshotPushStateStore(root: root)
        #expect(store.state(appID: "app1").isEmpty)
        var state = ScreenshotPushState()
        state.kept[ScreenshotCellKey(locale: "de-DE", displayType: .iPhone, slot: 2)] = RenderKey(rawValue: "abc")
        state.queue(request("ja"))
        try store.save(state, appID: "app1")
        #expect(FileManager.default.fileExists(atPath: root.appending(path: "app1/push-state.json").path()))
        #expect(store.state(appID: "app1").kept == state.kept)
        #expect(store.state(appID: "app1").restores.map(\.id) == ["ja|b1"])
        #expect(store.state(appID: "app2").isEmpty)
    }
}
