//
//  AssistantSetupMethod.swift
//  AppLocalizer
//

import Foundation

/// Step 1's choice: an assistant the person already uses, over MCP, or an
/// API key AppLocalizer uses itself. Each says what it gives up.
enum AssistantSetupMethod: String, CaseIterable, Identifiable, Sendable {
    case assistant
    case apiKey

    var id: Self { self }

    var title: String {
        switch self {
        case .assistant: String(localized: "Connect an assistant you use")
        case .apiKey: String(localized: "Use an API key")
        }
    }

    var detail: String {
        switch self {
        case .assistant: String(localized: "Claude Code, Claude Desktop, Cursor, Codex or any MCP client.")
        case .apiKey: String(localized: "From Anthropic, OpenAI or Google Gemini.")
        }
    }

    /// The pluses and the minus: (is it a plus, what).
    var points: [(isPlus: Bool, text: String)] {
        switch self {
        case .assistant:
            [
                (true, String(localized: "Reads your code and git history itself")),
                (true, String(localized: "Uses the plan you already pay for")),
                (false, String(localized: "You paste a prompt to ask")),
            ]
        case .apiKey:
            [
                (true, String(localized: "Suggestions in one click, inside AppLocalizer")),
                (true, String(localized: "Nothing else to install")),
                (false, String(localized: "Billed per request, and it doesn’t read your code")),
            ]
        }
    }

    /// The labels under the four step bars.
    var stepTitles: [String] {
        switch self {
        case .assistant:
            [String(localized: "Assistant"), String(localized: "Local server"), String(localized: "Add to assistant"), String(localized: "Test")]
        case .apiKey:
            [String(localized: "Method"), String(localized: "API key"), String(localized: "What it sees"), String(localized: "Test")]
        }
    }
}
