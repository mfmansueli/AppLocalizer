//
//  ClaudeCodeToolUse.swift
//  AppLocalizer
//

import Foundation

/// One tool call in a run, as the output list shows it: what kind of step
/// it was and a short description, e.g. a command, a file read, or one of
/// AppLocalizer's own tools.
struct ClaudeCodeToolUse: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// One of AppLocalizer's MCP tools.
        case appLocalizer
        case command
        case file
        case search
        case other
    }

    var id: String
    /// As Claude Code names it: "Bash", "Read", "mcp__applocalizer__get_listing".
    var name: String
    var kind: Kind
    /// "git log v1.3..HEAD --oneline", "Read CHANGELOG.md", "get_listing".
    var summary: String

    static let appLocalizerPrefix = "mcp__\(MCPEndpoint.serverName)__"

    init(id: String, name: String, input: JSONValue?) {
        self.id = id
        self.name = name
        (kind, summary) = Self.describe(name: name, input: input)
    }

    /// The kind and summary for `name` called with `input`.
    static func describe(name: String, input: JSONValue?) -> (Kind, String) {
        if name.hasPrefix(appLocalizerPrefix) {
            return (.appLocalizer, String(name.dropFirst(appLocalizerPrefix.count)))
        }
        let string = { (key: String) in input?[key]?.stringValue.map(shortened) }
        switch name {
        case "Bash":
            return (.command, string("command") ?? name)
        case "Read":
            return (.file, String(localized: "Read \(string("file_path").map(fileName) ?? "a file")"))
        case "Edit", "Write", "NotebookEdit":
            return (.file, "\(name) \(string("file_path").map(fileName) ?? "")".trimmingCharacters(in: .whitespaces))
        case "Grep":
            let pattern = string("pattern") ?? ""
            if isPlain(pattern) { return (.search, String(localized: "Search for “\(pattern)”")) }
            // A regular expression reads as noise in the run's card.
            guard let place = string("path").map(fileName) ?? string("glob") else {
                return (.search, String(localized: "Search the project’s files"))
            }
            return (.search, String(localized: "Search \(place)"))
        case "Glob":
            return (.search, String(localized: "Find \(string("pattern") ?? "files")"))
        default:
            if name.hasPrefix("mcp__") {
                // Another server's tool: its own name, after the server's.
                let parts = name.split(separator: "_", omittingEmptySubsequences: true)
                return (.other, parts.count > 2 ? parts.dropFirst(2).joined(separator: "_") : name)
            }
            return (.other, name)
        }
    }

    /// Words to look for, not a regular expression: MB Admin's run showed
    /// `"startTime":[0-9.]+,"title":"(Added attachment named '[^']+'|Tap …`.
    static func isPlain(_ pattern: String) -> Bool {
        !pattern.isEmpty && pattern.count <= 60 && !pattern.contains(where: "[](){}|\\^$*+?".contains)
    }

    /// One line, at most 160 characters.
    private static func shortened(_ text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        return line.count > 160 ? String(line.prefix(159)) + "…" : line
    }

    /// The last path component, or the text when it has none.
    private static func fileName(_ path: String) -> String {
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? path : name
    }
}
