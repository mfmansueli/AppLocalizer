//
//  ExportComplianceAnswers.swift
//  AppLocalizer
//

import Foundation

/// The five export compliance answers. App Store Connect's API takes only
/// what they add up to, per build: `usesNonExemptEncryption`. The answers
/// themselves are kept on this Mac (`AppInformationNotes`).
struct ExportComplianceAnswers: Hashable, Codable, Sendable {
    var answers: [ExportComplianceQuestion: Bool] = [:]

    subscript(question: ExportComplianceQuestion) -> Bool? {
        get { answers[question] }
        set { answers[question] = newValue }
    }

    /// The questions that apply: the rest only matter once the app uses
    /// encryption.
    var visibleQuestions: [ExportComplianceQuestion] {
        guard self[.usesEncryption] == true else { return [.usesEncryption] }
        return ExportComplianceQuestion.allCases
    }

    /// What the build is told; nil until encryption is answered.
    var usesNonExemptEncryption: Bool? {
        switch self[.usesEncryption] {
        case false?: false
        case true?: self[.isExempt].map { !$0 }
        case nil: nil
        }
    }

    /// The page column's line: "Exempt", "Docs needed", "Not answered".
    var status: String {
        switch usesNonExemptEncryption {
        case false?: String(localized: "Exempt")
        case true?: String(localized: "Docs needed")
        case nil: String(localized: "Not answered")
        }
    }

    /// Answers implied by a build's flag, when nothing better is known.
    init(usesNonExemptEncryption: Bool?) {
        switch usesNonExemptEncryption {
        case false?: answers = [.usesEncryption: false]
        case true?: answers = [.usesEncryption: true, .isExempt: false]
        case nil: answers = [:]
        }
    }

    init(answers: [ExportComplianceQuestion: Bool] = [:]) {
        self.answers = answers
    }
}
