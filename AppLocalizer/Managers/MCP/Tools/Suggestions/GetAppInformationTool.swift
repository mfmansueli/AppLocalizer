//
//  GetAppInformationTool.swift
//  AppLocalizer
//

import Foundation

/// `get_app_information`: what `suggest_fields` works on for App
/// Information: General's copyright, categories and release, Age Rating's
/// questions, Accessibility's features per device, and App Review's contact
/// and notes, with App Store Connect's values where they differ, the
/// choices of picked fields and answers, and the open suggestions.
struct GetAppInformationTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "get_app_information",
        title: "Get App Information for suggestions",
        description: """
        Reads an app's App Information in AppLocalizer for suggestions, for the newest editable version (else \
        the live one): page general (copyright, primaryCategory, secondaryCategory, release), page ageRating \
        (one entry per question, with its answers), page accessibility (per device, one entry per feature with \
        Apple's meaning, answered Yes or No) and page review (contactFirstName, contactLastName, contactPhone, \
        contactEmail, notes). Each field has its current value, App Store Connect's (`live`) where it differs, \
        its limit, and whether it's locked (the version is in review or live); an unanswered question or \
        feature has value null. Categories and release are picked from `choices`, by id. `suggestions` lists \
        the ones already open with their source. Send suggestions with suggest_fields.
        """,
        inputSchema: MCPToolDefinition.schema(
            ["appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps.")],
            required: ["appId"]
        )
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let draft = try await MCPAppInformationDraft.load(app: arguments.string("appId"), in: context.workspace)
        let open = context.workspace.suggestions?.open(for: draft.app.id, area: .appInformation) ?? []
        let pages = AppInformationSuggestionField.pages.map { page -> JSONValue in
            let fields = AppInformationSuggestionField.fields(on: page).map { field in (field.rawValue, Self.entry(for: field, in: draft)) }
            return [
                "page": .string(SuggestFieldsTool.mcpPageName(page.rawValue)),
                "fields": .object(Dictionary(uniqueKeysWithValues: fields)),
            ]
        }
        let result: JSONValue = [
            "appId": .string(draft.app.id),
            "app": .string(draft.app.name),
            "version": draft.versionJSON,
            "pages": .array(pages + [Self.ageRating(in: draft), Self.accessibility(in: draft)]),
            "choices": [
                "categories": .array(AppCategory.all.map { ["id": .string($0.id), "name": .string($0.name)] }),
                "release": .array(ReleaseOption.allCases.map { ["id": .string($0.rawValue), "name": .string($0.title)] }),
            ],
            "suggestions": .array(open.map(\.mcpJSON)),
        ]
        return .read(result, target: draft.target(nil))
    }

    private static func entry(for field: AppInformationSuggestionField, in draft: MCPAppInformationDraft) -> JSONValue {
        let value = draft.value(field)
        var entry: [String: JSONValue] = [
            "value": .string(value),
            "locked": .bool(draft.isLocked(field)),
            "limit": field.limit.map { ["max": .int($0), "unit": "characters"] } ?? .null,
        ]
        if field.isPicked, !value.isEmpty { entry["name"] = .string(field.displayValue(value)) }
        let live = draft.liveValue(field)
        if live != value { entry["live"] = .string(live) }
        return .object(entry)
    }

    /// Every question, or `available: false` before App Store Connect has a
    /// questionnaire for the app.
    private static func ageRating(in draft: MCPAppInformationDraft) -> JSONValue {
        let questions = AgeRatingQuestion.allCases.map { question in
            var entry = answerEntry(.ageRating(question), in: draft)
            entry["title"] = .string(question.title)
            return (question.rawValue, JSONValue.object(entry))
        }
        return [
            "page": .string(AppInformationPage.ageRating.rawValue),
            "available": .bool(draft.slots.canSuggest(.ageRating(.wellness))),
            "questions": .object(Dictionary(uniqueKeysWithValues: questions)),
        ]
    }

    /// One entry per device the app runs on, with the features asked there.
    private static func accessibility(in draft: MCPAppInformationDraft) -> JSONValue {
        let devices = draft.slots.accessibilityFamilies.map { family -> JSONValue in
            let features = family.features.map { feature in
                var entry = answerEntry(.accessibility(family, feature), in: draft)
                entry["name"] = .string(feature.name)
                entry["meaning"] = .string(feature.meaning)
                return (feature.rawValue, JSONValue.object(entry))
            }
            return [
                "device": .string(family.mcpName),
                "name": .string(family.name),
                "declared": .bool(draft.slots.card(for: family)?.shown != nil),
                "features": .object(Dictionary(uniqueKeysWithValues: features)),
            ]
        }
        return [
            "page": .string(AppInformationPage.accessibility.rawValue),
            "available": .bool(draft.slots.accessibility != nil),
            "devices": .array(devices),
        ]
    }

    /// `value` and `live` by name ("Yes", "Infrequent"; null when
    /// unanswered) and the answers it takes.
    private static func answerEntry(_ slot: AppInformationSuggestionSlot, in draft: MCPAppInformationDraft) -> [String: JSONValue] {
        func name(_ value: String) -> JSONValue { value.isEmpty ? .null : .string(slot.displayValue(value)) }
        let value = draft.slots.value(slot)
        var entry: [String: JSONValue] = [
            "value": name(value),
            "answers": .array(slot.choices.map { .string(slot.displayValue($0)) }),
        ]
        let live = draft.slots.liveValue(slot)
        if live != value { entry["live"] = name(live) }
        return entry
    }
}
