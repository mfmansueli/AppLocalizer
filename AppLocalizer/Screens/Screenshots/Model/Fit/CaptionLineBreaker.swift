//
//  CaptionLineBreaker.swift
//  AppLocalizer
//

import CoreFoundation
import Foundation

/// Breaks a caption into lines no wider than the box, the way the locale
/// breaks lines: Core Text's line-break opportunities for word scripts
/// (with Thai's dictionary breaks), and between any two characters for
/// Chinese, Japanese and Korean, with kinsoku (no line starts with 、。」？
/// and the like, none ends with an opening bracket). Hyphenation, when on,
/// uses the locale's dictionary and only for words wider than the box.
/// Explicit line breaks in the caption are kept.
struct CaptionLineBreaker {
    var locale: Locale
    var script: ScreenshotScript
    var hyphenate: Bool
    /// The width of a piece of text with the caption's font, in pixels.
    var measure: (String) -> CGFloat

    struct LineBreaks: Hashable {
        var lines: [String]
        /// A word is wider than the box and couldn't be hyphenated.
        var hasWideWord: Bool
    }

    private static let tolerance: CGFloat = 0.5

    /// No line may start with these.
    private static let noLineStart = Set("、。，．,.」』）〕】〉》〙〗｝]）)？！?!ー・：；:;ゃゅょっぁぃぅぇぉゎァィゥェォッャュョヮヵヶ々〻…‥ゝゞヽヾ%％")
    /// No line may end with these.
    private static let noLineEnd = Set("「『（〔【〈《〘〖｛[（(")

    func lines(for text: String, width: CGFloat) -> LineBreaks {
        var lines: [String] = []
        var hasWideWord = false
        for paragraph in text.components(separatedBy: .newlines) {
            let result = breakParagraph(paragraph, width: width)
            lines += result.lines
            hasWideWord = hasWideWord || result.hasWideWord
        }
        return LineBreaks(lines: lines, hasWideWord: hasWideWord)
    }

    // MARK: - Greedy fill

    private func breakParagraph(_ text: String, width: CGFloat) -> LineBreaks {
        var lines: [String] = []
        var current = ""
        var hasWideWord = false
        for segment in segments(of: text) {
            if current.isEmpty {
                current = segment
            } else if fits(current + segment, width) {
                current += segment
                continue
            } else {
                lines.append(Self.trimmed(current))
                current = segment
            }
            // `current` is a single segment here; it may be wider than the box.
            guard !fits(current, width) else { continue }
            if hyphenate, let pieces = hyphenated(current, width: width) {
                lines += pieces.dropLast()
                current = pieces.last ?? ""
            } else {
                hasWideWord = true
            }
        }
        if !Self.trimmed(current).isEmpty || lines.isEmpty { lines.append(Self.trimmed(current)) }
        return LineBreaks(lines: lines, hasWideWord: hasWideWord)
    }

    private func fits(_ text: String, _ width: CGFloat) -> Bool {
        measure(Self.trimmed(text)) <= width + Self.tolerance
    }

    private static func trimmed(_ text: String) -> String {
        var text = text
        while let last = text.last, last.isWhitespace { text.removeLast() }
        return text
    }

    // MARK: - Segments

    /// The pieces a line may break between, each with its trailing spaces.
    func segments(of text: String) -> [String] {
        let words = lineBreakSegments(of: text)
        guard script.breaksBetweenCharacters else { return words }
        return applyKinsoku(to: words.flatMap(Self.characterSegments))
    }

    private func lineBreakSegments(of text: String) -> [String] {
        let string = text as NSString
        let tokenizer = CFStringTokenizerCreate(
            nil, text as CFString, CFRange(location: 0, length: string.length),
            kCFStringTokenizerUnitLineBreak, locale as CFLocale
        )
        var segments: [String] = []
        var end = 0
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            if range.location > end, !segments.isEmpty {
                segments[segments.count - 1] += string.substring(with: NSRange(location: end, length: range.location - end))
            }
            segments.append(string.substring(with: NSRange(location: range.location, length: range.length)))
            end = range.location + range.length
        }
        if end < string.length {
            let rest = string.substring(from: end)
            if segments.isEmpty { segments.append(rest) } else { segments[segments.count - 1] += rest }
        }
        return segments
    }

    /// A segment of CJK text split into characters; runs of Latin letters
    /// and digits (an app name, "iCloud") stay whole.
    private static func characterSegments(_ segment: String) -> [String] {
        var pieces: [String] = []
        var word = ""
        for character in segment {
            if isWordCharacter(character) {
                word.append(character)
                continue
            }
            if !word.isEmpty {
                pieces.append(word)
                word = ""
            }
            if character.isWhitespace, !pieces.isEmpty {
                pieces[pieces.count - 1].append(character)
            } else {
                pieces.append(String(character))
            }
        }
        if !word.isEmpty { pieces.append(word) }
        return pieces
    }

    private static func isWordCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { scalar in
            scalar.isASCII ? (scalar.properties.isAlphabetic || ("0"..."9").contains(scalar) || scalar == "'" || scalar == "-") : false
        }
    }

    /// Glues characters that may not start a line to the one before, and
    /// ones that may not end a line to the one after.
    private func applyKinsoku(to pieces: [String]) -> [String] {
        var glued: [String] = []
        var carry = ""
        for piece in pieces {
            let text = carry + piece
            carry = ""
            if let first = text.first, Self.noLineStart.contains(first), !glued.isEmpty {
                glued[glued.count - 1] += text
            } else {
                glued.append(text)
            }
            if let last = glued.last?.last, Self.noLineEnd.contains(last) {
                carry = glued.removeLast()
            }
        }
        if !carry.isEmpty { glued.append(carry) }
        return glued
    }

    // MARK: - Hyphenation

    /// `word` split at the locale's hyphenation points into pieces that fit,
    /// each but the last ending in a hyphen; nil when the dictionary has no
    /// point that helps.
    private func hyphenated(_ word: String, width: CGFloat) -> [String]? {
        guard CFStringIsHyphenationAvailableForLocale(locale as CFLocale) else { return nil }
        var pieces: [String] = []
        var rest = Self.trimmed(word)
        let trailing = String(word.dropFirst(rest.count))
        while !fits(rest, width) {
            guard let split = bestSplit(of: rest, width: width) else { return nil }
            pieces.append(String(rest.prefix(split)) + "-")
            rest = String(rest.dropFirst(split))
        }
        pieces.append(rest + trailing)
        return pieces.count > 1 ? pieces : nil
    }

    /// The longest prefix length, in characters, ending at a hyphenation
    /// point that fits with its hyphen.
    private func bestSplit(of word: String, width: CGFloat) -> Int? {
        let string = word as NSString
        var index = string.length
        while index > 0 {
            let location = CFStringGetHyphenationLocationBeforeIndex(
                word as CFString, index, CFRange(location: 0, length: string.length), 0, locale as CFLocale, nil
            )
            guard location != kCFNotFound, location > 0 else { return nil }
            let prefix = string.substring(to: location)
            if fits(prefix + "-", width) { return prefix.count }
            index = location
        }
        return nil
    }
}
