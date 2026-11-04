//
//  ArtworkPromptFiller.swift
//  AppLocalizer
//

import Foundation

/// Fills a prompt: its `{{block:id}}`s with the shared blocks, its
/// `{{placeholders}}` with the run's values (a value nobody gave reads
/// "unknown"), and leaves out what a place the run doesn't make would ask:
/// the search parts in a header-only run, the header parts in a
/// search-only run, the 16:9 parts unless the run makes that image.
struct ArtworkPromptFiller {
    var values: [String: String]
    var size: AutopilotArtworkSize
    /// Reads a prompt's text; the bundle's resource files by default.
    var text: (ArtworkPromptID) -> String = { ArtworkPromptLibrary.text($0) }

    /// What a value nobody gave reads.
    static let unknown = "unknown"

    /// `id`'s text, filled.
    func fill(_ id: ArtworkPromptID) -> String {
        var prompt = text(id)
        for block in ArtworkPromptID.allCases where block.isBlock {
            prompt = prompt.replacingOccurrences(of: "{{block:\(block.rawValue)}}", with: text(block))
        }
        prompt = Self.filling(prompt, with: values)
        return Self.leavingOut(prompt, size: size)
    }

    /// Every `{{key}}` in `text` replaced by its value, else "unknown".
    static func filling(_ text: String, with values: [String: String]) -> String {
        var result = ""
        var rest = text[...]
        while let open = rest.range(of: "{{") {
            result += rest[..<open.lowerBound]
            guard let close = rest[open.upperBound...].range(of: "}}") else {
                rest = rest[open.lowerBound...]
                break
            }
            let key = String(rest[open.upperBound..<close.lowerBound])
            let value = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines)
            result += (value?.isEmpty == false ? value : nil) ?? unknown
            rest = rest[close.upperBound...]
        }
        return result + rest
    }

    /// The prompt's keys, `{{block:…}}` included.
    static func keys(in text: String) -> [String] {
        var keys: [String] = []
        var rest = text[...]
        while let open = rest.range(of: "{{"), let close = rest[open.upperBound...].range(of: "}}") {
            keys.append(String(rest[open.upperBound..<close.lowerBound]))
            rest = rest[close.upperBound...]
        }
        return keys
    }

    // MARK: - Places the run doesn't make

    /// The sentences that ask for one place, within a line.
    private static let sentences: [(text: String, place: Place)] = [
        ("Search: 1 phrase of 2–5 words. ", .search),
        ("Header: at most 1 phrase, or none (\"the app name only\"). ", .header),
        ("No interface or devices in the header. ", .header),
        (" On the header, the top 22% sits under the status bar, Back and Share, so keep it calm.", .header),
        (", \"search\": \"2–5 words in ", .search),
        ("\"header\": \"2–5 words in ", .header),
    ]

    private enum Place { case header, search, wide }

    /// `text` without what asks for a place the run doesn't make.
    static func leavingOut(_ text: String, size: AutopilotArtworkSize) -> String {
        var left: Set<Place> = []
        switch size {
        case .headerAndSearch: left = [.wide]
        case .headerOnly: left = [.search, .wide]
        case .searchOnly: left = [.header, .wide]
        case .wide: left = []
        }
        guard !left.isEmpty else { return text }
        var lines: [String] = []
        var skippingDeeperThan: Int?
        for line in text.components(separatedBy: "\n") {
            let indent = line.prefix { $0 == " " }.count
            if let depth = skippingDeeperThan {
                if indent > depth, !line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
                skippingDeeperThan = nil
            }
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let place = listPlace(of: trimmed), left.contains(place) {
                skippingDeeperThan = indent
                continue
            }
            if left.contains(.search), trimmed.hasPrefix("\"search_layout\"") || trimmed.contains("on the search page") { continue }
            lines.append(cutting(line, left: left))
        }
        return lines.joined(separator: "\n")
    }

    /// The place a list item is about: "- Header: …", "- Search results:
    /// …", "- 16:9: …".
    private static func listPlace(of line: String) -> Place? {
        if line.hasPrefix("- Header:") { return .header }
        if line.hasPrefix("- Search:") || line.hasPrefix("- Search results:") { return .search }
        if line.hasPrefix("- 16:9:") { return .wide }
        return nil
    }

    /// `line` without the sentences about places left out; a JSON value
    /// about one runs to its closing quote.
    private static func cutting(_ line: String, left: Set<Place>) -> String {
        var line = line
        for sentence in sentences where left.contains(sentence.place) {
            guard let range = line.range(of: sentence.text) else { continue }
            if sentence.text.hasSuffix("words in ") {
                // `, "search": "2–5 words in en-US"` or `"header": "…, or null", `.
                guard let close = line[range.upperBound...].firstIndex(of: "\"") else { continue }
                var end = line.index(after: close)
                if sentence.place == .header, line[end...].hasPrefix(", ") { end = line.index(end, offsetBy: 2) }
                line.removeSubrange(range.lowerBound..<end)
            } else {
                line.removeSubrange(range)
            }
        }
        return line
    }
}
