//
//  FieldSuggestion+MCP.swift
//  AppLocalizer
//

import Foundation

extension FieldSuggestion {
    /// As `get_store_page` and `get_app_information` list open suggestions,
    /// so an assistant doesn't send the same thing again.
    var mcpJSON: JSONValue {
        var entry: [String: JSONValue] = [
            "id": .string(id),
            "field": .string(target.field),
            "value": .string(value),
            "reason": .string(reason),
            "source": .string(source.title),
        ]
        switch target.scope {
        case let .storePage(locale): entry["locale"] = .string(locale)
        case let .appInformation(page): entry["page"] = .string(SuggestFieldsTool.mcpPageName(page))
        case let .accessibility(family):
            entry["page"] = .string(AppInformationPage.accessibility.rawValue)
            entry["device"] = .string(DeviceFamily(rawValue: family)?.mcpName ?? family)
        }
        return .object(entry)
    }
}
