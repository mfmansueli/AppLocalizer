//
//  PrivacyTestSupport.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Suggestions, evidence and worksheets for App Privacy's tests.
enum PrivacyTestSupport {
    static let client = "Claude Code"
    static let date = Date(timeIntervalSince1970: 1_793_000_000)

    /// Collected, linked when `linked`, for `purposes`.
    static func collected(_ purposes: Set<PrivacyPurpose> = [.appFunctionality], linked: Bool = false, tracking: Bool = false) -> PrivacyAnswer {
        PrivacyAnswer(collected: true, purposes: purposes, linked: linked, tracking: tracking)
    }

    static func suggestion(
        _ answer: PrivacyAnswer,
        confidence: PrivacyConfidence = .high,
        evidence: [PrivacyEvidence] = [],
        client: String = client
    ) -> PrivacySuggestion {
        PrivacySuggestion(answer: answer, confidence: confidence, rationale: "Because the code says so.", evidence: evidence, client: client)
    }

    /// Sentry's manifest entry declaring `type`.
    static func manifest(_ type: PrivacyDataType, sdk: String = "Sentry", version: String = "8.36.0") -> PrivacyEvidence {
        PrivacyEvidence(kind: .sdkManifest, sdk: sdk, version: version, entry: type.manifestKey)
    }

    /// A worksheet with these suggestions proposed, nothing reviewed.
    static func proposed(_ suggestions: [(PrivacyDataType, PrivacySuggestion)]) -> PrivacyWorksheet {
        var worksheet = PrivacyWorksheet()
        for (type, suggestion) in suggestions {
            worksheet.propose(suggestion, for: type, at: date)
        }
        return worksheet
    }

    /// Yes to the first question and these answers, all the person's.
    static func answered(_ answers: [PrivacyDataType: PrivacyAnswer]) -> PrivacyWorksheet {
        var worksheet = PrivacyWorksheet()
        worksheet.setCollects(true)
        for (type, answer) in answers {
            worksheet.edit(type, to: answer)
        }
        return worksheet
    }

    static func question(
        _ id: String = "q1",
        affects: [PrivacyDataType] = [.email],
        ifYes: PrivacyAnswer? = PrivacyTestSupport.collected(linked: true),
        ifNo: PrivacyAnswer? = .notCollected
    ) -> PrivacyOpenQuestion {
        PrivacyOpenQuestion(
            id: id,
            question: "Does the support backend keep the email address?",
            affects: affects,
            ifYes: ifYes.map { PrivacyQuestionEffect(summary: "Collected", answer: $0) },
            ifNo: ifNo.map { PrivacyQuestionEffect(summary: "Not collected", answer: $0) },
            client: client
        )
    }
}
