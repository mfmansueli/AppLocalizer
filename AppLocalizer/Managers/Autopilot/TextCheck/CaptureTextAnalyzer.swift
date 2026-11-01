//
//  CaptureTextAnalyzer.swift
//  AppLocalizer
//

import Foundation
import NaturalLanguage

/// Turns the lines Vision read in a capture into `CaptureTextFacts`,
/// leaving out the status bar and lines Vision isn't sure of: the language
/// most of the text is in (Natural Language), lines a label cut off with
/// an ellipsis, and the app's name in quotes, as every iOS permission
/// prompt shows it ("“Lumen” Would Like to Send You Notifications",
/// "„Lumen“ möchte dir Mitteilungen senden", "「Lumen」は通知を送信します").
enum CaptureTextAnalyzer {
    /// The status bar's share of the image's height: its time is no
    /// language.
    static let statusBarHeight = 0.06
    static let minimumConfidence = 0.4
    /// Less text than this says nothing about the language.
    static let minimumLetters = 40
    /// How sure Natural Language must be of the language.
    static let minimumLanguageShare = 0.6

    static let quotes: Set<Character> = ["“", "”", "„", "«", "»", "「", "」", "『", "』", "\"", "‘", "’", "‚", "‹", "›"]

    static func facts(of reading: CaptureTextReading, appName: String) -> CaptureTextFacts {
        let lines = reading.lines
            .filter { $0.confidence >= minimumConfidence && $0.top >= statusBarHeight }
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return CaptureTextFacts(
            language: reading.readsLanguage ? dominantLanguage(of: lines.joined(separator: "\n")) : nil,
            truncatedLines: lines.filter(isTruncated),
            promptLine: lines.first { quotesName(in: $0, appName: appName) }
        )
    }

    /// "en", "de", "zh-Hans"; nil when there's too little text or no clear
    /// winner.
    static func dominantLanguage(of text: String) -> String? {
        guard text.count(where: \.isLetter) >= minimumLetters else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let (language, share) = recognizer.languageHypotheses(withMaximum: 1).first, share >= minimumLanguageShare else { return nil }
        return language.rawValue
    }

    /// "Einträge durchsu…": an ellipsis straight after a letter, as a label
    /// cuts a word. "Loading …" or "…" alone isn't.
    static func isTruncated(_ line: String) -> Bool {
        var text = Substring(line)
        if text.hasSuffix("…") {
            text = text.dropLast()
        } else if text.hasSuffix("...") {
            text = text.dropLast(3)
        } else {
            return false
        }
        guard text.last?.isLetter == true else { return false }
        return text.count(where: \.isLetter) >= 3
    }

    /// The app's name in quotes of any language.
    static func quotesName(in line: String, appName: String) -> Bool {
        let text = line.lowercased()
        return names(of: appName).contains { name in
            var searched = text.startIndex..<text.endIndex
            while let range = text.range(of: name, range: searched) {
                if isQuote(before: range.lowerBound, in: text), isQuote(after: range.upperBound, in: text) { return true }
                searched = range.upperBound..<text.endIndex
            }
            return false
        }
    }

    /// The names an app's prompts might quote: "Lumen Journal: Daily
    /// Diary" → "lumen journal: daily diary", "lumen journal", "lumen".
    static func names(of appName: String) -> [String] {
        let full = appName.lowercased().trimmingCharacters(in: .whitespaces)
        var names = [full]
        for separator in [":", " - ", " – ", " — ", " |"] {
            if let head = full.components(separatedBy: separator).first?.trimmingCharacters(in: .whitespaces) { names.append(head) }
        }
        if let first = full.split(separator: " ").first, first.count >= 3 { names.append(String(first)) }
        var seen = Set<String>()
        return names.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static func isQuote(before index: String.Index, in text: String) -> Bool {
        text[..<index].last { !$0.isWhitespace }.map(quotes.contains) ?? false
    }

    private static func isQuote(after index: String.Index, in text: String) -> Bool {
        text[index...].first { !$0.isWhitespace }.map(quotes.contains) ?? false
    }
}
