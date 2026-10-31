//
//  MCPSuggestionItem.swift
//  AppLocalizer
//

import Foundation

/// One item of a `suggest_fields` call: `{area, locale | page, device,
/// field, value, reason, evidence}`, or of a `begin_suggestions` plan,
/// which has no value. Only the shape is checked here; the tool checks the
/// field, the limit and the permissions.
struct MCPSuggestionItem: Hashable, Sendable {
    var area: SuggestionArea
    /// A Store Page locale code, e.g. `de-DE`.
    var locale: String?
    /// An App Information page: `general`, `ageRating`, `accessibility`
    /// or `review`.
    var page: String?
    /// For Accessibility: `iphone`, `watch`, …
    var device: String?
    var field: String
    /// Exactly as sent: line breaks in What’s New matter.
    var value: String
    var reason: String
    var evidence: [SuggestionEvidence]

    /// `isPlanned`: a plan's entry, which names a field without a value.
    init(_ object: [String: JSONValue], isPlanned: Bool = false) throws {
        let arguments = MCPToolArguments(object)
        let areaName = try arguments.optionalString("area")
        if let areaName {
            guard let area = SuggestionArea(rawValue: areaName.lowercased()) else {
                throw MCPToolError.invalidArgument(name: "area", expected: String(localized: "store or info"))
            }
            self.area = area
        } else {
            // A locale means the Store Page; a page, App Information.
            area = object["page"] != nil ? .appInformation : .storePage
        }
        locale = try arguments.optionalString("locale")
        page = try arguments.optionalString("page")
        device = try arguments.optionalString("device")
        field = try arguments.string("field")
        guard let value = object["value"]?.stringValue ?? (isPlanned ? "" : nil) else {
            throw MCPToolError.invalidArgument(name: "value", expected: String(localized: "a string"))
        }
        self.value = value
        reason = try arguments.optionalString("reason") ?? ""
        evidence = try (arguments.optionalArray("evidence") ?? []).map { entry in
            guard let kind = entry["kind"]?.stringValue, let ref = entry["ref"]?.stringValue else {
                throw MCPToolError.invalidArgument(name: "evidence", expected: String(localized: "a list of {kind, ref} objects"))
            }
            return SuggestionEvidence(kind: kind, ref: ref)
        }
    }
}
