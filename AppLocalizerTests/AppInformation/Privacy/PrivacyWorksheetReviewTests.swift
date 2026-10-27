//
//  PrivacyWorksheetReviewTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The person's edits: accepting, rejecting and editing suggestions,
/// Accept All High-Confidence, conflicts, open questions and the
/// cross-check's two ways out.
@Suite("PrivacyWorksheet review")
struct PrivacyWorksheetReviewTests {
    private typealias Support = PrivacyTestSupport

    @Test func acceptingASuggestionMakesItCount() {
        var worksheet = Support.proposed([(.userId, Support.suggestion(Support.collected(linked: true)))])
        #expect(worksheet.reviewedAnswers.collected.isEmpty)
        worksheet.acceptCollects()
        worksheet.accept(.userId)
        #expect(worksheet[.userId]?.status == .accepted)
        #expect(worksheet.reviewedAnswers.collected[.userId] == Support.collected(linked: true))
    }

    @Test func aCollectedSuggestionWithoutAPurposeCantBeAccepted() {
        var worksheet = Support.proposed([(.email, Support.suggestion(PrivacyAnswer(collected: true)))])
        worksheet.accept(.email)
        #expect(worksheet[.email]?.status == .unreviewed)
        #expect(worksheet.missingPurposeTypes == [.email])
    }

    @Test func rejectingMakesTheTypeNotCollectedAndThePersons() {
        var worksheet = Support.proposed([(.deviceId, Support.suggestion(Support.collected([.analytics])))])
        worksheet.reject(.deviceId)
        #expect(worksheet[.deviceId]?.answer == .notCollected)
        #expect(worksheet[.deviceId]?.status == .rejected)
        #expect(worksheet[.deviceId]?.status.isReviewed == true)
    }

    @Test func editingASuggestionMarksItEditedAndAnswerByHandIsYours() {
        var worksheet = Support.proposed([(.crash, Support.suggestion(Support.collected()))])
        worksheet.edit(.crash, to: Support.collected([.appFunctionality, .analytics]))
        #expect(worksheet[.crash]?.status == .edited)
        worksheet.edit(.email, to: Support.collected(linked: true))
        #expect(worksheet[.email]?.status == .yours)
        worksheet.edit(.phone, to: .notCollected)
        #expect(worksheet[.phone] == nil)
    }

    @Test func acceptAllHighConfidenceLeavesLowConflictsAndOpenQuestions() {
        var worksheet = Support.proposed([
            (.userId, Support.suggestion(Support.collected(linked: true))),
            (.crash, Support.suggestion(Support.collected())),
            (.coarseLocation, Support.suggestion(Support.collected(), confidence: .low)),
            (.email, Support.suggestion(Support.collected(linked: true))),
        ])
        worksheet.ask(Support.question(affects: [.email]), at: Support.date)
        worksheet[.crash]?.conflict = Support.suggestion(.notCollected)
        #expect(worksheet.highConfidenceTypes == [.userId])
        #expect(worksheet.acceptAllHighConfidence() == 1)
        #expect(worksheet[.userId]?.status == .accepted)
        #expect(worksheet[.coarseLocation]?.status == .unreviewed)
        #expect(worksheet[.email]?.status == .unreviewed)
        #expect(worksheet.collects?.status == .accepted)
    }

    @Test func keepYoursDropsTheAssistantsAnswerAndUseTheirsReplacesYours() {
        var worksheet = Support.answered([.deviceId: Support.collected([.analytics], linked: true)])
        worksheet.propose(Support.suggestion(Support.collected([.analytics])), for: .deviceId, at: Support.date)
        #expect(worksheet.conflictTypes == [.deviceId])

        var kept = worksheet
        kept.keepYours(.deviceId)
        #expect(kept.conflictTypes.isEmpty)
        #expect(kept[.deviceId]?.answer.linked == true)

        worksheet.useAssistants(.deviceId)
        #expect(worksheet.conflictTypes.isEmpty)
        #expect(worksheet[.deviceId]?.answer.linked == false)
        #expect(worksheet[.deviceId]?.status == .accepted)
    }

    @Test func answeringAQuestionAppliesItsEffect() {
        var worksheet = Support.proposed([(.email, Support.suggestion(.notCollected, confidence: .low))])
        worksheet.edit(.support, to: .notCollected)
        worksheet.ask(Support.question(affects: [.email, .support]), at: Support.date)
        worksheet.answerQuestion("q1", with: true)
        #expect(worksheet.openQuestions.isEmpty)
        // Unreviewed stays unreviewed, with the new answer.
        #expect(worksheet[.email]?.status == .unreviewed)
        #expect(worksheet[.email]?.answer == Support.collected(linked: true))
        // Anything else becomes the person's.
        #expect(worksheet[.support]?.answer == Support.collected(linked: true))
        #expect(worksheet[.support]?.status == .yours)
    }

    @Test func markCollectedUsesTheAssistantsPurposesAndExplainingSilencesTheCrossCheck() {
        var worksheet = Support.answered([:])
        worksheet.propose(
            Support.suggestion(Support.collected([.analytics]), evidence: [Support.manifest(.otherDiagnostics)]),
            for: .otherDiagnostics,
            at: Support.date
        )
        worksheet.reject(.otherDiagnostics)
        #expect(worksheet.mismatches.map(\.type) == [.otherDiagnostics])
        #expect(worksheet.mismatches.first?.sdk == "Sentry 8.36.0")

        var marked = worksheet
        marked.markCollected(.otherDiagnostics)
        #expect(marked[.otherDiagnostics]?.answer.purposes == [.analytics])
        #expect(marked.mismatches.isEmpty)

        worksheet.explainNotCollected(.otherDiagnostics, because: "  ")
        #expect(!worksheet.mismatches.isEmpty)
        worksheet.explainNotCollected(.otherDiagnostics, because: "Diagnostics are turned off.")
        #expect(worksheet.mismatches.isEmpty)
    }
}
