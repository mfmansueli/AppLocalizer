//
//  SuggestionsSummary.swift
//  AppLocalizer
//

import Foundation

/// The overview's Suggestions card: an app's open field suggestions per
/// page (Store Page, General, Age Rating, Accessibility, App Review) and
/// per source.
struct SuggestionsSummary: Hashable, Sendable {
    private var counts: [SuggestionPage: Int] = [:]
    var builtInCount = 0
    var assistantCount = 0
    var aiProviderCount = 0
    /// The assistant that sent the newest, e.g. "Claude Code".
    var assistantName: String?

    init(open suggestions: [FieldSuggestion]) {
        for suggestion in suggestions {
            if let page = SuggestionPage(suggestion.target.scope) { counts[page, default: 0] += 1 }
            switch suggestion.source {
            case .builtIn: builtInCount += 1
            case .assistant: assistantCount += 1
            case .aiProvider: aiProviderCount += 1
            }
        }
        assistantName = suggestions.filter(\.source.isAssistant).max { $0.createdAt < $1.createdAt }?.source.assistantName
    }

    var total: Int { counts.values.reduce(0, +) }

    func count(on page: SuggestionPage) -> Int {
        counts[page] ?? 0
    }

    /// "5 to review", or "All reviewed".
    var pillText: String {
        total > 0 ? String(localized: "\(total) to review") : String(localized: "All reviewed")
    }

    /// "6 · 2 coming" while Suggest Everything sends more, "3", "None", or
    /// "Locked" when the page can't change now.
    func text(on page: SuggestionPage, coming: Int = 0, isLocked: Bool = false) -> String {
        let count = count(on: page)
        if coming > 0 { return String(localized: "\(count) · \(coming) coming") }
        if count > 0 { return count.formatted() }
        return isLocked ? String(localized: "Locked") : String(localized: "None")
    }

    /// "Built-in 2 · Claude Code 3 · AI provider 0"; `assistant` names the
    /// connected one when none has sent anything yet.
    func sourcesText(assistant: String?) -> String {
        let name = assistantName ?? assistant ?? String(localized: "Assistant")
        return [
            String(localized: "Built-in \(builtInCount.formatted())"),
            "\(name) \(assistantCount.formatted())",
            String(localized: "AI provider \(aiProviderCount.formatted())"),
        ].joined(separator: " · ")
    }
}
