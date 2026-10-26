//
//  PrivacyWorksheet+MCP.swift
//  AppLocalizer
//

import Foundation

extension PrivacyWorksheet {
    /// The worksheet as `get_privacy_questionnaire` returns it: the first
    /// question, each answered type with who answered and where it stands,
    /// and the questions still open.
    var questionnaireJSON: JSONValue {
        let answers: [JSONValue] = PrivacyDataType.allCases.compactMap { type in
            guard let entry = entries[type] else { return nil }
            var object = entry.answer.mcpJSON
            object["type"] = .string(type.rawValue)
            object["status"] = .string(entry.status.rawValue)
            object["answeredBy"] = .string(entry.client ?? "the person")
            if entry.conflict != nil { object["note"] = "Your earlier answer differs from the person's; they will pick one." }
            return .object(object)
        }
        return [
            "collects": collects.map { .bool($0.value) } ?? .null,
            "answers": .array(answers),
            "openQuestions": .array(openQuestions.map { ["id": .string($0.id), "question": .string($0.question)] }),
            "markedPublished": publication.map { .string($0.date.formatted(.iso8601)) } ?? .null,
        ]
    }
}
