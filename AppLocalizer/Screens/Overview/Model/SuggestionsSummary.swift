//
//  SuggestionsSummary.swift
//  AppLocalizer
//

import Foundation

/// The overview's Suggestions card: an app's open field suggestions by area,
/// by Store Page language, and by source.
struct SuggestionsSummary: Hashable, Sendable {
    /// One Store Page language with suggestions open.
    struct LocaleCount: Hashable, Sendable {
        var name: String
        var count: Int
    }

    var storePageCount = 0
    /// Most first, then by name.
    var locales: [LocaleCount] = []
    var appInformationCount = 0
    var builtInCount = 0
    var assistantCount = 0
    var aiProviderCount = 0
    /// The assistant that sent the newest, e.g. "Claude Code".
    var assistantName: String?

    init(open suggestions: [FieldSuggestion]) {
        var perLocale: [String: Int] = [:]
        for suggestion in suggestions {
            switch suggestion.target.scope {
            case let .storePage(code):
                storePageCount += 1
                perLocale[StoreLocaleCatalog.locale(code: code)?.name ?? code, default: 0] += 1
            case .appInformation, .accessibility:
                appInformationCount += 1
            }
            switch suggestion.source {
            case .builtIn: builtInCount += 1
            case .assistant: assistantCount += 1
            case .aiProvider: aiProviderCount += 1
            }
        }
        locales = perLocale.map { LocaleCount(name: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
        assistantName = suggestions.filter(\.source.isAssistant).max { $0.createdAt < $1.createdAt }?.source.assistantName
    }

    var total: Int { storePageCount + appInformationCount }

    /// "5 to review", or "All reviewed".
    var pillText: String {
        total > 0 ? String(localized: "\(total) to review") : String(localized: "All reviewed")
    }

    /// "5 · English (U.S.) 3 · German 2", or "None".
    var storePageText: String {
        guard storePageCount > 0 else { return String(localized: "None") }
        return ([storePageCount.formatted()] + locales.map { "\($0.name) \($0.count.formatted())" }).joined(separator: " · ")
    }

    var appInformationText: String {
        appInformationCount > 0 ? appInformationCount.formatted() : String(localized: "None")
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
