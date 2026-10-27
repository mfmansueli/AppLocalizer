//
//  AgeRatingQuestion+MCP.swift
//  AppLocalizer
//

import Foundation

extension AgeRatingQuestion {
    /// The question an assistant means: its id (`cartoonViolence`) or App
    /// Store Connect's attribute (`violenceCartoonOrFantasy`), ignoring case.
    static func matching(_ text: String) -> AgeRatingQuestion? {
        let wanted = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allCases.first { $0.rawValue.lowercased() == wanted || $0.apiKey.lowercased() == wanted }
    }

    /// The entry in `get_age_rating`'s `questions`.
    func mcpJSON(current values: AgeRatingValues) -> JSONValue {
        [
            "id": .string(rawValue),
            "question": .string(title),
            "group": .string(group.title),
            "answers": .array(answers.map { .string($0.rawValue) }),
            "current": values.isAnswered(self) ? .string(values.answers[self].rawValue) : .null,
        ]
    }
}
