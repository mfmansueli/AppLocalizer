//
//  ArtworkTextLengthTests.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
import Testing
@testable import AppLocalizer

/// How long a search headline or header line reads, in words where there
/// are spaces and in half-width characters everywhere.
@Suite("Artwork text length")
struct ArtworkTextLengthTests {
    @Test func aShortSearchHeadlinePasses() {
        #expect(!ArtworkTextLength.isLongForSearch("Plan your week in seconds", locale: .englishUS))
        #expect(!ArtworkTextLength.isLongForSearch("Dein Tagebuch", locale: .german))
    }

    @Test func aLongGermanHeadlineIsTooLongForSearch() {
        let line = "Behalte deine Gewohnheiten jeden Tag mühelos im Blick"
        #expect(ArtworkTextLength.words(in: line) == 8)
        #expect(ArtworkTextLength.isLongForSearch(line, locale: .german))
        // Few words, but too wide: one long German compound.
        let compound = "Haushaltsbuchführungsassistent für Familien"
        #expect(ArtworkTextLength.words(in: compound) == 3)
        #expect(ArtworkTextLength.isLongForSearch(compound, locale: .german))
    }

    @Test func chineseAndJapaneseCountCharactersNotWords() {
        // 11 wide characters: 22 half-width, under 32.
        #expect(ArtworkTextLength.width(of: "一日をすっきり整理する") == 22)
        #expect(!ArtworkTextLength.isLongForSearch("一日をすっきり整理する", locale: .japanese))
        // 21 wide characters: 42, over.
        #expect(ArtworkTextLength.isLongForSearch("毎日の習慣を簡単に記録して振り返りましょう", locale: .japanese))
        #expect(ArtworkTextLength.isUnspaced(.japanese))
        #expect(!ArtworkTextLength.isUnspaced(.german))
    }

    @Test func aHeaderLineIsAboutThreeWords() {
        #expect(!ArtworkTextLength.isLongForHeader("Your calm place", locale: .englishUS))
        #expect(ArtworkTextLength.isLongForHeader("Your calm place to write", locale: .englishUS))
        #expect(!ArtworkTextLength.isLongForHeader("心を整える", locale: .japanese))
        #expect(ArtworkTextLength.isLongForHeader("毎日の気持ちを静かに書き留める", locale: .japanese))
    }

    @Test func aLoneDashIsntAWord() {
        #expect(ArtworkTextLength.words(in: "Write — then rest") == 3)
    }
}
#endif
