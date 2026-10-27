//
//  CaptureFileNameTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("Capture file names and locale folders")
struct CaptureFileNameTests {
    @Test func readsFastlaneSnapshotNames() {
        let name = CaptureFileName("iPhone 17 Pro Max-03_Search.png")
        #expect(name.deviceName == "iPhone 17 Pro Max")
        #expect(name.slotNumber == 3)
        #expect(name.slotName == "Search")
    }

    @Test func readsXcodeAttachmentNamesWithoutTheirRepetitionAndID() {
        let name = CaptureFileName("01_Today_0_9F2C1A3B-77D1-4E0F-A2B4-1C2D3E4F5A6B.png")
        #expect(name.deviceName == nil)
        #expect(name.slotNumber == 1)
        #expect(name.slotName == "Today")
    }

    @Test func readsPlainNumberedNames() {
        #expect(CaptureFileName("02-Week.png").slotNumber == 2)
        #expect(CaptureFileName("02-Week.png").slotName == "Week")
        #expect(CaptureFileName("4.png").slotNumber == 4)
        #expect(CaptureFileName("Home.png").slotNumber == nil)
    }

    @Test func findsTheLocaleAFolderOrConfigurationNames() {
        #expect(CaptureLocaleHint.code(in: "de-DE") == "de-DE")
        #expect(CaptureLocaleHint.code(in: "pt") == "pt")
        #expect(CaptureLocaleHint.code(in: "German") == "de-DE")
        #expect(CaptureLocaleHint.code(in: "Lumen-ja.xcresult") == "ja")
        #expect(CaptureLocaleHint.code(in: "Lumen_zh-Hans") == "zh-Hans")
        #expect(CaptureLocaleHint.code(in: "screenshots") == nil)
        #expect(CaptureLocaleHint.code(in: "fastlane") == nil)
    }
}
