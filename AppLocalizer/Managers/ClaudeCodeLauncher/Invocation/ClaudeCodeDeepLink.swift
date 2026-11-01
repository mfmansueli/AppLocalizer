//
//  ClaudeCodeDeepLink.swift
//  AppLocalizer
//

import AppKit

/// Open in Terminal: Claude Code's own link,
/// `claude-cli://open?cwd=<folder>&q=<prompt>`, opens an interactive session
/// in the folder with the prompt typed in, waiting for Return. It works once
/// Claude Code has registered the link on this Mac (after its first
/// interactive session), and keeps prompts to 5,000 characters.
enum ClaudeCodeDeepLink {
    static let scheme = "claude-cli"
    static let maximumPromptLength = 5000

    /// Characters a query value keeps as they are.
    private static let valueCharacters: CharacterSet = {
        var characters = CharacterSet.urlQueryAllowed
        characters.remove(charactersIn: "&=+?#/")
        return characters
    }()

    /// The link, or nil when the prompt is too long for it.
    static func url(folder: String, prompt: String?) -> URL? {
        var query = "cwd=\(encoded(folder))"
        if let prompt, !prompt.isEmpty {
            guard prompt.count <= maximumPromptLength else { return nil }
            query += "&q=\(encoded(prompt))"
        }
        return URL(string: "\(scheme)://open?\(query)")
    }

    private static func encoded(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: valueCharacters) ?? value
    }

    /// Whether some app on this Mac opens the link.
    @MainActor
    static var isAvailable: Bool {
        guard let probe = URL(string: "\(scheme)://open") else { return false }
        return NSWorkspace.shared.urlForApplication(toOpen: probe) != nil
    }

    /// Opens the link; false when nothing on this Mac handles it.
    @MainActor
    @discardableResult
    static func open(folder: String, prompt: String?) -> Bool {
        guard isAvailable, let url = url(folder: folder, prompt: prompt) else { return false }
        return NSWorkspace.shared.open(url)
    }
}
