//
//  PrivacyWorksheetProposalTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// What an assistant's suggestions do to the worksheet: new ones wait
/// unreviewed, the person's answers are never overwritten, and a scan is
/// recorded with what changed since the last one.
@Suite("PrivacyWorksheet proposals")
struct PrivacyWorksheetProposalTests {
    private typealias Support = PrivacyTestSupport

    @Test func aNewSuggestionWaitsUnreviewedAndAnswersTheFirstQuestion() {
        var worksheet = PrivacyWorksheet()
        let outcome = worksheet.propose(Support.suggestion(Support.collected()), for: .crash, at: Support.date)
        #expect(outcome == .queued)
        #expect(worksheet[.crash]?.status == .unreviewed)
        #expect(worksheet.collects?.value == true)
        #expect(worksheet.collects?.status == .unreviewed)
        #expect(worksheet.unreviewedCount == 2)
    }

    @Test func aDifferentSuggestionReplacesAnUnreviewedOrAcceptedOne() {
        var worksheet = Support.proposed([(.crash, Support.suggestion(Support.collected()))])
        worksheet.accept(.crash)
        let outcome = worksheet.propose(Support.suggestion(Support.collected([.analytics])), for: .crash, at: Support.date)
        #expect(outcome == .queued)
        #expect(worksheet[.crash]?.status == .unreviewed)
        #expect(worksheet[.crash]?.answer.purposes == [.analytics])
    }

    @Test(arguments: [PrivacyRowStatus.yours, .edited, .rejected])
    func theAnswerThePersonGaveStaysAndTheNewOneIsAConflict(status: PrivacyRowStatus) {
        var worksheet = PrivacyWorksheet()
        worksheet[.deviceId] = PrivacyTypeEntry(answer: Support.collected([.analytics], linked: true), status: status)
        let outcome = worksheet.propose(Support.suggestion(Support.collected([.analytics])), for: .deviceId, at: Support.date)
        #expect(outcome == .conflict)
        #expect(worksheet[.deviceId]?.answer.linked == true)
        #expect(worksheet[.deviceId]?.status == status)
        #expect(worksheet[.deviceId]?.conflict?.answer.linked == false)
        // The same conflict again changes nothing.
        #expect(worksheet.propose(Support.suggestion(Support.collected([.analytics])), for: .deviceId, at: Support.date) == .unchanged)
    }

    @Test func theSameAnswerOnlyRefreshesTheEvidence() {
        var worksheet = Support.answered([.crash: Support.collected()])
        let outcome = worksheet.propose(Support.suggestion(Support.collected(), evidence: [Support.manifest(.crash)]), for: .crash, at: Support.date)
        #expect(outcome == .unchanged)
        #expect(worksheet[.crash]?.status == .yours)
        #expect(worksheet[.crash]?.suggestion?.evidence.count == 1)
        #expect(worksheet.manifestDeclarations[.crash] == ["Sentry 8.36.0"])
    }

    @Test func theFirstQuestionKeepsThePersonsAnswer() {
        var worksheet = PrivacyWorksheet()
        worksheet.setCollects(false)
        #expect(worksheet.proposeCollects(true, confidence: .high, by: Support.client) == .conflict)
        #expect(worksheet.collects?.value == false)
        var fresh = PrivacyWorksheet()
        #expect(fresh.proposeCollects(true, confidence: .high, by: Support.client) == .queued)
        #expect(fresh.proposeCollects(true, confidence: .high, by: Support.client) == .unchanged)
    }

    @Test func anAnsweredQuestionStaysAnswered() {
        var worksheet = PrivacyWorksheet()
        #expect(worksheet.ask(Support.question(), at: Support.date) == .queued)
        worksheet.answerQuestion("q1", with: false)
        var again = Support.question()
        again.question = "Reworded"
        #expect(worksheet.ask(again, at: Support.date) == .unchanged)
        #expect(worksheet.questions.first?.answer == false)
    }

    @Test func aScanRunsUntilFinishedAndRecordsWhatChanged() throws {
        var worksheet = PrivacyWorksheet()
        let first = Support.date
        worksheet.recordScanDetails(PrivacyScan(assistant: Support.client, ranAt: first, sdks: [PrivacySDK(name: "Sentry", version: "8.36.0")]), at: first)
        worksheet.propose(Support.suggestion(Support.collected()), for: .crash, at: first)
        #expect(worksheet.activeScan(at: first) != nil)
        worksheet.finishScan(at: first)
        #expect(worksheet.runningScan == nil)
        #expect(worksheet.lastScan?.suggestionCount == 1)
        #expect(worksheet.lastScan?.changes == nil)

        let second = first.addingTimeInterval(14 * 24 * 60 * 60)
        worksheet.recordScanDetails(PrivacyScan(assistant: Support.client, ranAt: second, sdks: [PrivacySDK(name: "Mixpanel", version: "4.3.0")]), at: second)
        worksheet.propose(Support.suggestion(Support.collected()), for: .crash, at: second)
        worksheet.propose(Support.suggestion(Support.collected([.analytics]), confidence: .medium), for: .coarseLocation, at: second)
        worksheet.finishScan(at: second)
        let changes = try #require(worksheet.lastScan?.changes)
        #expect(changes.since == first)
        #expect(changes.addedSDKs.map(\.name) == ["Mixpanel"])
        #expect(changes.removedSDKs.map(\.name) == ["Sentry"])
        #expect(changes.changedTypes == [.coarseLocation])
        #expect(changes.unchangedCount == 1)
    }

    @Test func aScanGoesQuietAfterHalfAnHour() {
        var worksheet = PrivacyWorksheet()
        worksheet.beginScan(by: Support.client, at: Support.date)
        #expect(worksheet.activeScan(at: Support.date.addingTimeInterval(29 * 60)) != nil)
        #expect(worksheet.activeScan(at: Support.date.addingTimeInterval(31 * 60)) == nil)
    }
}
