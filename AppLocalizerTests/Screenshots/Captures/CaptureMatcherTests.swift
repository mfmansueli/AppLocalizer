//
//  CaptureMatcherTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

@Suite("CaptureMatcher")
struct CaptureMatcherTests {
    private let phone = ScreenshotDisplayType.iPhone.portraitPixelSize

    private func file(
        _ path: String, locale: String?, device: String? = "iPhone 17 Pro Max", slot: Int?, size: PixelSize? = nil
    ) -> CaptureCandidate {
        CaptureCandidate(
            path: path, origin: .file(URL(filePath: "/captures/\(path)")), source: .fastlane, pixelSize: size ?? phone,
            localeCode: locale, deviceName: device, slotNumber: slot, slotName: nil
        )
    }

    @Test func matchesFastlaneFilesToLocaleDisplayTypeAndSlot() throws {
        let rows = CaptureMatcher(slotCount: 5).rows(for: [
            file("de-DE/iPhone 17 Pro Max-03_Search.png", locale: "de-DE", slot: 3),
            file("ja/iPad Pro 13-inch (M5)-04_Photos.png", locale: "ja", device: "iPad Pro 13-inch (M5)", slot: 4, size: PixelSize(width: 2752, height: 2064)),
        ])
        #expect(rows.allSatisfy { !$0.needsYou })
        let german = try #require(rows.first { $0.path.hasPrefix("de-DE") }?.placement)
        #expect(german == CaptureMatchRow.Placement(locale: "de-DE", displayType: .iPhone, slot: 2))
        let japanese = try #require(rows.first { $0.path.hasPrefix("ja") }?.placement)
        #expect(japanese == CaptureMatchRow.Placement(locale: "ja", displayType: .iPad, slot: 3))
    }

    @Test func aLanguageWithOneAppStoreLocaleMatchesIt() {
        let rows = CaptureMatcher(slotCount: 5).rows(for: [file("de/1.png", locale: "de", device: nil, slot: 1)])
        #expect(rows.first?.placement?.locale == "de-DE")
        #expect(rows.first?.needsYou == false)
    }

    @Test func anAmbiguousFolderIsOneRowOfferingItsLocalesOrSkip() throws {
        let rows = CaptureMatcher(slotCount: 5).rows(for: (1...5).map { (number: Int) in file("pt/iPhone 17 Pro Max-0\(number)_A.png", locale: "pt", slot: number) })
        let row = try #require(rows.first)
        #expect(rows.count == 1)
        #expect(row.files.count == 5)
        #expect(row.issue?.message == "“pt” isn’t an App Store locale.")
        #expect(row.options.map(\.title) == ["Portuguese (Brazil)", "Portuguese (Portugal)", "Skip these 5 files"])
        #expect(row.choice == .locale("pt-BR"))
        #expect(row.items.map(\.placement.locale) == Array(repeating: "pt-BR", count: 5))
        var skipped = row
        skipped.choice = .skip
        #expect(skipped.items.isEmpty)
    }

    @Test func anUnknownLocaleCanOnlyBeSkipped() throws {
        let row = try #require(CaptureMatcher(slotCount: 5).rows(for: [file("xx/1.png", locale: "xx", slot: 1)]).first)
        #expect(row.issue == .unknownLocale(code: "xx"))
        #expect(row.options.map(\.choice) == [.skip])
        #expect(row.items.isEmpty)
    }

    @Test func aSmallerDevicesCaptureOffersSkipOrScaleUp() throws {
        let rows = CaptureMatcher(slotCount: 5).rows(for: [
            file("en-US/iPhone 17 Pro Max-03_Search.png", locale: "en-US", slot: 3),
            file("en-US/iPhone 16e-03_Search.png", locale: "en-US", device: "iPhone 16e", slot: 3, size: PixelSize(width: 1170, height: 2532)),
        ])
        let row = try #require(rows.first { $0.needsYou })
        #expect(row.issue?.message == "Taken on iPhone 16e (1170 × 2532). The 6.9″ set needs 1320 × 2868.")
        #expect(row.options.map(\.title) == ["Skip it, the 17 Pro Max capture is there", "Use it, scaled up 113%"])
        #expect(row.items.isEmpty)
        var used = row
        used.choice = .scaleUp
        #expect(used.items.first?.placement == CaptureMatchRow.Placement(locale: "en-US", displayType: .iPhone, slot: 2))
    }

    @Test func aSlotPastTheTemplatesOffersToAddIt() throws {
        let row = try #require(CaptureMatcher(slotCount: 5).rows(for: [file("de-DE/iPhone 17 Pro Max-06_Settings.png", locale: "de-DE", slot: 6)]).first)
        #expect(row.issue?.message == "Slot 6, but the template has 5 slots.")
        #expect(row.options.map(\.title) == ["Skip", "Add slot 6 to the template"])
        var added = row
        added.choice = .addSlot(6)
        #expect(added.slotsNeeded == 6)
        #expect(added.items.first?.placement.slot == 5)
    }

    @Test func withoutATemplateAnySlotUpToTenMatches() {
        let rows = CaptureMatcher(slotCount: nil).rows(for: [
            file("de-DE/iPhone 17 Pro Max-06_Settings.png", locale: "de-DE", slot: 6),
            file("de-DE/iPhone 17 Pro Max-11_More.png", locale: "de-DE", slot: 11),
        ])
        #expect(rows.first { $0.path.contains("-06") }?.needsYou == false)
        #expect(rows.first { $0.path.contains("-11") }?.issue == .tooManySlots(number: 11))
    }

    @Test func filesWithoutANumberTakeTheirPlaceInNameOrder() {
        let rows = CaptureMatcher(slotCount: 5).rows(for: [
            file("fr-FR/b-week.png", locale: "fr-FR", device: nil, slot: nil),
            file("fr-FR/a-today.png", locale: "fr-FR", device: nil, slot: nil),
        ])
        #expect(rows.map(\.placement?.slot) == [0, 1])
        #expect(rows.map(\.path) == ["fr-FR/a-today.png", "fr-FR/b-week.png"])
    }

    @Test func anImageWithoutASizeOrDeviceNeedsYou() {
        let unreadable = CaptureCandidate(
            path: "de-DE/x.png", origin: .file(URL(filePath: "/x.png")), source: .folder, pixelSize: nil, localeCode: "de-DE", slotNumber: 1
        )
        #expect(CaptureMatcher(slotCount: 5).rows(for: [unreadable]).first?.issue == .unknownDevice(size: nil))
    }
}
