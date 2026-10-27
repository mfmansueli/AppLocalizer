//
//  KeywordAnalysisTests.swift
//  AppLocalizerTests
//

import Testing
@testable import AppLocalizer

@Suite("KeywordAnalysis")
struct KeywordAnalysisTests {
    /// The keyword editor's German example.
    private let german = KeywordAnalysis(
        keywords: "tagebuch, stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,rückblick,notizen,stimmung",
        name: "Lumen: Tagebuch",
        subtitle: "Private Notizen, sanfte Fragen"
    )

    @Test func germanExampleCounts() {
        #expect(german.byteCount == 114)
        #expect(german.isOverLimit)
        #expect(german.counter.text == "114 / 100 bytes")
        #expect(german.tokens.count == 11)
        #expect(german.duplicateCount == 1)
        #expect(german.inNameOrSubtitleCount == 2)
        #expect(german.wastedSpaceBytes == 1)
        #expect(german.summary == "1 duplicate · 2 already in name or subtitle · 1 wasted space")
    }

    @Test func germanExampleTokenStates() {
        let states = Dictionary(german.tokens.map { ($0.index, $0.state) }, uniquingKeysWith: { first, _ in first })
        #expect(states[0] == .inNameOrSubtitle)
        #expect(states[1] == .useful)
        #expect(states[9] == .inNameOrSubtitle)
        #expect(states[10] == .duplicate)
        #expect(german.tokens[1].text == "stimmung")
        #expect(german.tokens[8].byteCount == 10)
        #expect(german.tokens[9].accessibilityLabel == "notizen, already in the name or subtitle")
        #expect(german.tokens[10].accessibilityLabel == "stimmung, duplicate")
        #expect(german.tokens[1].accessibilityLabel == "stimmung")
    }

    @Test func optimizingTheGermanExample() {
        #expect(german.optimized == "stimmung,dankbarkeit,reflexion,schreiben,achtsamkeit,gewohnheit,erinnerungen,rückblick")
        #expect(ListingTextMeasure.utf8Bytes(in: german.optimized) == 87)
        #expect(german.bytesSaved == 27)
        #expect(german.canOptimize)
        #expect(german.optimizeTitle == "Optimize · saves 27 bytes")
    }

    @Test func duplicatesIgnoreCaseDiacriticsAndWidth() {
        let analysis = KeywordAnalysis(keywords: "Reflexion,reflexión,ＰＤＦ,pdf", name: "Lumen", subtitle: "")
        #expect(analysis.tokens.map(\.state) == [.useful, .duplicate, .useful, .duplicate])
        #expect(analysis.optimized == "Reflexion,ＰＤＦ")
    }

    @Test func multiWordTokensNeedEveryWordCovered() {
        let analysis = KeywordAnalysis(keywords: "sanfte fragen,sanfte tage", name: "Lumen", subtitle: "Private Notizen, sanfte Fragen")
        #expect(analysis.tokens.map(\.state) == [.inNameOrSubtitle, .useful])
    }

    @Test func cleanKeywordsHaveNothingToOptimize() {
        let analysis = KeywordAnalysis(keywords: "journal,diary,mood", name: "Lumen: Daily Journal", subtitle: "Private notes")
        #expect(analysis.tokens.map(\.state) == [.inNameOrSubtitle, .useful, .useful])
        let clean = KeywordAnalysis(keywords: "diary,mood", name: "Lumen: Daily Journal", subtitle: "Private notes")
        #expect(clean.summary == "No wasted bytes")
        #expect(!clean.canOptimize)
        #expect(clean.optimized == clean.keywords)
    }

    @Test func spacesAroundTokensAreWasted() {
        let analysis = KeywordAnalysis(keywords: " diary , mood,  , gratitude", name: "", subtitle: "")
        #expect(analysis.tokens.map(\.text) == ["diary", "mood", "gratitude"])
        #expect(analysis.wastedSpaceBytes == 6)
        #expect(analysis.summary == "6 wasted spaces")
        #expect(analysis.optimized == "diary,mood,gratitude")
    }

    @Test func removingATokenKeepsTheRestAsTyped() {
        #expect(german.removingToken(at: 0) == german.keywords.replacingOccurrences(of: "tagebuch,", with: ""))
        let analysis = KeywordAnalysis(keywords: "a, b,,c ", name: "", subtitle: "")
        #expect(analysis.removingToken(at: 2) == "a, b,")
        #expect(analysis.removingToken(at: 9) == "a, b,,c ")
    }

    @Test func emptyKeywords() {
        let analysis = KeywordAnalysis(keywords: "", name: "Lumen", subtitle: "")
        #expect(analysis.tokens.isEmpty)
        #expect(analysis.byteCount == 0)
        #expect(analysis.summary == "No wasted bytes")
    }
}
