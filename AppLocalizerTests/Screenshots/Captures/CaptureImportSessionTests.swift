//
//  CaptureImportSessionTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("CaptureImportSession")
struct CaptureImportSessionTests {
    /// The design's fastlane import: 52 matched across ten locales and two
    /// display types, and three rows that need you.
    private var session: CaptureImportSession {
        let scan = ScreenshotsSampleData.fastlaneScan
        return CaptureImportSession(source: scan.source, location: scan.location, rows: CaptureMatcher(slotCount: 5).rows(for: scan.candidates))
    }

    @Test func summarizesTheMatch() {
        let session = session
        #expect(session.title == "fastlane snapshot output · 55 files")
        #expect(session.location == "~/Developer/Lumen/fastlane/screenshots")
        #expect(session.matchedText == "52 matched")
        #expect(session.needsYouText == "3 need you")
        #expect(session.spreadText == "10 locales · 2 display types")
        #expect(session.warning == nil)
    }

    @Test func importsTheMatchedFilesAndWhatEachChoiceBringsIn() throws {
        var session = session
        // The pt file defaults to Portuguese (Brazil); the others to skip.
        #expect(session.items.count == 53)
        #expect(session.importTitle == "Import 53 Captures")
        let portuguese = try #require(session.rows.first { $0.path.hasPrefix("pt/") })
        session.choose(.skip, forRow: portuguese.id)
        #expect(session.importTitle == "Import 52 Captures")

        let extra = try #require(session.rows.first { $0.path.contains("-06_") })
        session.choose(.addSlot(6), forRow: extra.id)
        #expect(session.slotsNeeded == 6)
        #expect(session.items.count == 53)

        // A choice the row doesn't offer is ignored.
        session.choose(.scaleUp, forRow: extra.id)
        #expect(session.rows.first { $0.id == extra.id }?.choice == .addSlot(6))
    }

    @Test func liveScreenshotsWarnAboutCaptionsTheyMayHave() {
        let session = CaptureImportSession(source: .appStoreConnect, location: "App Store Connect", rows: [])
        #expect(session.warning?.hasPrefix("These are the screenshots live in App Store Connect.") == true)
        #expect(session.title == "App Store Connect · 0 live screenshots")
    }
}
