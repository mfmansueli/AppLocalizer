//
//  PrivacyOpenQuestion.swift
//  AppLocalizer
//

import Foundation

/// Something the code can't answer, asked by the assistant, e.g. "Does
/// your support backend keep the email address after it replies?". It
/// names the data types it affects and what each answer changes. The
/// worksheet isn't done while one is open.
struct PrivacyOpenQuestion: Identifiable, Hashable, Codable, Sendable {
    /// The assistant's id, e.g. "q1"; asking again with the same id
    /// replaces the question.
    var id: String
    var question: String
    var affects: [PrivacyDataType]
    var ifYes: PrivacyQuestionEffect?
    var ifNo: PrivacyQuestionEffect?
    var client: String
    /// Nil while it's open.
    var answer: Bool?

    var isOpen: Bool { answer == nil }

    /// "Email Address, Customer Support".
    var affectedNames: String {
        affects.map(\.name).joined(separator: ", ")
    }

    func effect(of answer: Bool) -> PrivacyQuestionEffect? {
        answer ? ifYes : ifNo
    }

    /// What the given answer did, e.g. "Both are marked not collected.", or
    /// a plain line when the assistant didn't say.
    var effectSummary: String? {
        guard let answer else { return nil }
        if let summary = effect(of: answer)?.summary, !summary.isEmpty { return summary }
        return answer
            ? String(localized: "Answered Yes. Check \(affectedNames) with that in mind.")
            : String(localized: "Answered No. Check \(affectedNames) with that in mind.")
    }
}
