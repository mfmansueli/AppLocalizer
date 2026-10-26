//
//  CaptionLineBreakerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Lines break the way the locale does: at words for Latin, between
/// characters for Japanese with kinsoku, and hyphenated only when a word
/// is wider than the box.
@MainActor
@Suite("CaptionLineBreaker")
struct CaptionLineBreakerTests {
    /// Every character is 10 px wide.
    private func breaker(_ identifier: String, _ script: ScreenshotScript, hyphenate: Bool = false) -> CaptionLineBreaker {
        CaptionLineBreaker(locale: Locale(identifier: identifier), script: script, hyphenate: hyphenate) { CGFloat($0.count * 10) }
    }

    @Test func latinBreaksBetweenWords() {
        let lines = breaker("en_US", .latin).lines(for: "Write a little every day", width: 140)
        #expect(lines.lines == ["Write a little", "every day"])
        #expect(!lines.hasWideWord)
    }

    @Test func japaneseBreaksBetweenCharactersWithKinsoku() {
        let japanese = breaker("ja_JP", .japanese)
        #expect(japanese.segments(of: "今日は、いい天気。") == ["今", "日", "は、", "い", "い", "天", "気。"])
        let lines = japanese.lines(for: "今日は、いい天気。", width: 30).lines
        #expect(lines == ["今日", "は、い", "い天", "気。"])
        #expect(!lines.contains { $0.hasPrefix("、") || $0.hasPrefix("。") })
    }

    @Test func latinRunsInsideJapaneseStayWhole() {
        #expect(breaker("ja_JP", .japanese).segments(of: "Lumenで書く") == ["Lumen", "で", "書", "く"])
    }

    @Test func aWordWiderThanTheBoxIsReportedWithoutHyphenation() {
        let lines = breaker("de_DE", .latin).lines(for: "Tagebucheinträge", width: 100)
        #expect(lines.hasWideWord)
    }

    @Test func hyphenationSplitsOnlyWordsWiderThanTheBox() {
        let lines = breaker("de_DE", .latin, hyphenate: true).lines(for: "Tagebucheinträge", width: 100)
        #expect(!lines.hasWideWord)
        #expect(lines.lines.count > 1)
        #expect(lines.lines.dropLast().allSatisfy { $0.hasSuffix("-") })
    }

    @Test func explicitLineBreaksAreKept() {
        #expect(breaker("en_US", .latin).lines(for: "One\nTwo", width: 500).lines == ["One", "Two"])
    }
}
