//
//  CaptureTextAnalyzerTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Reading a capture's lines: its language, cut-off labels and permission
/// prompts, leaving out the status bar and lines Vision isn't sure of.
@Suite("Capture text analyzer")
struct CaptureTextAnalyzerTests {
    private static func reading(_ texts: [String], readsLanguage: Bool = true) -> CaptureTextReading {
        let lines = texts.enumerated().map { index, text in
            RecognizedTextLine(text: text, confidence: 0.9, top: 0.1 + Double(index) * 0.05)
        }
        return CaptureTextReading(lines: lines, readsLanguage: readsLanguage)
    }

    private static let german = [
        "Diese Woche", "Fünf Einträge, meistens ruhig", "Ein langer Spaziergang am Fluss mit Freunden",
        "Abendessen mit Ana und ihrer Familie", "Schreibe jeden Tag ein wenig",
    ]

    @Test func theLanguageIsTheOneMostOfTheTextIsIn() {
        #expect(CaptureTextAnalyzer.facts(of: Self.reading(Self.german), appName: "Lumen").language == "de")
        let english = ["This week", "Five entries, mostly calm", "A long walk by the river with friends", "Dinner with Ana and her family"]
        #expect(CaptureTextAnalyzer.facts(of: Self.reading(english), appName: "Lumen").language == "en")
        let japanese = ["今週", "5件のエントリー、ほぼ穏やか", "友達と川沿いを長く散歩しました", "アナとその家族と夕食を食べました", "毎日少しずつ書きましょう"]
        #expect(CaptureTextAnalyzer.facts(of: Self.reading(japanese), appName: "Lumen").language == "ja")
    }

    @Test func littleTextOrALanguageVisionCantReadSaysNothing() {
        #expect(CaptureTextAnalyzer.facts(of: Self.reading(["Today", "Week"]), appName: "Lumen").language == nil)
        #expect(CaptureTextAnalyzer.facts(of: Self.reading(Self.german, readsLanguage: false), appName: "Lumen").language == nil)
    }

    @Test func theStatusBarAndUnsureLinesAreLeftOut() {
        let reading = CaptureTextReading(lines: [
            RecognizedTextLine(text: "“Lumen” Would Like to Send You Notifications", confidence: 0.9, top: 0.01),
            RecognizedTextLine(text: "Einträge durchsu…", confidence: 0.2, top: 0.5),
        ], readsLanguage: true)
        #expect(CaptureTextAnalyzer.facts(of: reading, appName: "Lumen") == CaptureTextFacts(truncatedTops: [], ellipsisTops: []))
    }

    @Test(arguments: [
        ("Einträge durchsu…", true), ("Search...", true), ("Wochenübersi…", true), ("Message….", true),
        ("Loading …", false), ("…", false), ("Ab…", false), ("Today", false), ("Write something", false),
    ])
    func aLabelCutOffEndsInAnEllipsisRightAfterALetter(line: String, isCut: Bool) {
        #expect(CaptureTextAnalyzer.isTruncated(line) == isCut)
    }

    /// Every iOS permission prompt quotes the app's name, whatever the
    /// language's quotes.
    @Test(arguments: [
        ("“Lumen” Would Like to Send You Notifications", true),
        ("„Lumen“ möchte dir Mitteilungen senden", true),
        ("« Lumen » souhaite vous envoyer des notifications", true),
        ("「Lumen」は通知を送信します。よろしいですか?", true),
        ("Allow “Lumen Journal” to use your location?", true),
        ("Lumen is locked", false),
        ("Use Lumen every day", false),
    ])
    func aPromptQuotesTheAppsName(line: String, isPrompt: Bool) {
        #expect(CaptureTextAnalyzer.quotesName(in: line, appName: "Lumen Journal: Daily Diary") == isPrompt)
    }

    @Test func thePromptsMayQuoteTheNameBeforeItsSubtitleOrItsFirstWord() {
        #expect(CaptureTextAnalyzer.names(of: "Lumen Journal: Daily Diary") == ["lumen journal: daily diary", "lumen journal", "lumen"])
        #expect(CaptureTextAnalyzer.names(of: "Habitat — Plant Care") == ["habitat — plant care", "habitat"])
        #expect(CaptureTextAnalyzer.names(of: "Go") == ["go"])
    }

    @Test func theFactsKeepTheCutOffLinesAndThePrompt() {
        let facts = CaptureTextAnalyzer.facts(
            of: Self.reading(["Einträge durchsu…", "„Lumen“ möchte dir Mitteilungen senden", "Nicht erlauben"]), appName: "Lumen"
        )
        #expect(facts.truncatedLines == ["Einträge durchsu…"])
        #expect(facts.truncatedTops == [0.1])
        #expect(facts.promptLine == "„Lumen“ möchte dir Mitteilungen senden")
    }

    /// Every line ending in an ellipsis, cut or not, with where it is: in
    /// another language, a cut line at the same place is that element.
    @Test func theFactsKeepWhereEveryEllipsisIs() {
        let facts = CaptureTextAnalyzer.facts(of: Self.reading(["Today", "Loading …", "Message….", "We should go back together s..."]), appName: "Lumen")
        #expect(facts.truncatedLines == ["Message….", "We should go back together s..."])
        #expect(facts.truncatedTops == [0.2, 0.25])
        #expect(facts.ellipsisTops == [0.15, 0.2, 0.25])
    }
}
