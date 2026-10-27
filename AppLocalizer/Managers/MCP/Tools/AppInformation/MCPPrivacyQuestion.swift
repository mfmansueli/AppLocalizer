//
//  MCPPrivacyQuestion.swift
//  AppLocalizer
//

import Foundation

/// One item of `propose_privacy_answers`' `open_questions`: something the
/// code can't answer, the types it affects, and what Yes and No would mean
/// for them. Read into a `PrivacyOpenQuestion`, or refused with the reason.
struct MCPPrivacyQuestion {
    var question: PrivacyOpenQuestion?
    var refusal: String?
    /// The id it was sent with, for the result.
    var id: String

    init(_ object: [String: JSONValue], index: Int, client: String) {
        let text = object["question"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        id = object["id"]?.stringValue ?? "q\(index + 1)"
        guard !text.isEmpty else {
            refusal = String(localized: "An open question needs its question.")
            return
        }
        var affects: [PrivacyDataType] = []
        for value in object["affects"]?.arrayValue ?? [] {
            let name = value.stringValue ?? value.jsonString()
            guard let type = PrivacyDataType.matching(name) else {
                refusal = String(localized: "Unknown data type “\(name)”. Use an id from get_privacy_questionnaire.")
                return
            }
            affects.append(type)
        }
        question = PrivacyOpenQuestion(
            id: id,
            question: text,
            affects: affects,
            ifYes: object["if_yes"]?.objectValue.map(Self.effect),
            ifNo: object["if_no"]?.objectValue.map(Self.effect),
            client: client
        )
    }

    /// `{summary, collected?, purposes?, linked?, tracking?}`: what an
    /// answer means, and the answer it gives the affected types when it
    /// says.
    private static func effect(_ object: [String: JSONValue]) -> PrivacyQuestionEffect {
        let summary = object["summary"]?.stringValue ?? ""
        guard let collected = object["collected"]?.boolValue else { return PrivacyQuestionEffect(summary: summary, answer: nil) }
        let purposes = Set((object["purposes"]?.arrayValue ?? []).compactMap { $0.stringValue.flatMap(PrivacyPurpose.matching) })
        let answer = PrivacyAnswer(
            collected: collected,
            purposes: collected ? (purposes.isEmpty ? [.appFunctionality] : purposes) : [],
            linked: collected && object["linked"]?.boolValue == true,
            tracking: collected && object["tracking"]?.boolValue == true
        )
        return PrivacyQuestionEffect(summary: summary, answer: answer)
    }
}
