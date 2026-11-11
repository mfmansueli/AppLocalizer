//
//  PrivacyWorksheetStatusTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// Where the worksheet stands: reviewed answers only count, open questions
/// and conflicts block done, Mark as Published and Out of date, the filters
/// and the label preview.
@Suite("PrivacyWorksheet status")
struct PrivacyWorksheetStatusTests {
    private typealias Support = PrivacyTestSupport

    @Test func goesFromNotStartedToDoneToPublishedToOutOfDate() {
        var worksheet = PrivacyWorksheet()
        #expect(worksheet.status == .notStarted)
        worksheet.propose(Support.suggestion(Support.collected(linked: true)), for: .userId, at: Support.date)
        #expect(worksheet.status == .inProgress)
        worksheet.acceptAllHighConfidence()
        #expect(worksheet.status == .done)
        worksheet.markPublished(at: Support.date)
        #expect(worksheet.status == .published(Support.date))
        worksheet.edit(.userId, to: Support.collected(linked: false))
        #expect(worksheet.status == .outOfDate(Support.date))
        #expect(worksheet.status.needsAttention)
    }

    @Test func aNewSuggestionAfterPublishingIsOutOfDateToo() {
        var worksheet = Support.answered([.crash: Support.collected()])
        worksheet.markPublished(at: Support.date)
        worksheet.propose(Support.suggestion(Support.collected([.analytics]), confidence: .medium), for: .coarseLocation, at: Support.date)
        #expect(worksheet.status == .outOfDate(Support.date))
    }

    @Test func startingFromScratchIsInProgressUntilTheFirstQuestion() {
        var worksheet = PrivacyWorksheet()
        worksheet.start()
        #expect(worksheet.status == .inProgress)
        #expect(worksheet.blockedReason == "Finish the worksheet first: the first question.")
        worksheet.setCollects(false)
        #expect(worksheet.status == .done)
        #expect(worksheet.labelPreview.isDataNotCollected)
    }

    @Test func blockedReasonListsWhatsLeft() throws {
        var worksheet = Support.proposed([
            (.userId, Support.suggestion(Support.collected(linked: true))),
            (.email, Support.suggestion(Support.collected(linked: true), confidence: .low)),
        ])
        worksheet.ask(Support.question(), at: Support.date)
        let reason = try #require(worksheet.blockedReason)
        #expect(reason.hasPrefix("Finish the worksheet first: "))
        #expect(reason.contains("3 unreviewed"))
        #expect(reason.contains("1 open question"))
        #expect(!reason.contains("1 open questions"), "One question, singular")
        #expect(!worksheet.isDone)
    }

    @Test func unreviewedSuggestionsDontCountAnywhere() {
        var worksheet = Support.proposed([
            (.userId, Support.suggestion(Support.collected(linked: true))),
            (.crash, Support.suggestion(Support.collected())),
        ])
        worksheet.acceptCollects()
        worksheet.accept(.userId)
        #expect(worksheet.reviewedAnswers.collectedTypes == [.userId])
        #expect(worksheet.labelPreview.groups.map(\.kind) == [.linked])
        #expect(worksheet.checklistSteps.map(\.id) == ["s1", "s2", "d-userId", "s4"])
    }

    @Test func theLabelGroupsByTrackingThenLinkageAndCategory() {
        let worksheet = Support.answered([
            .deviceId: Support.collected([.thirdPartyAdvertising], linked: true, tracking: true),
            .userId: Support.collected(linked: true),
            .purchases: Support.collected(linked: true),
            .crash: Support.collected(),
        ])
        let preview = worksheet.labelPreview
        #expect(preview.isAnswered)
        #expect(preview.groups.map(\.kind) == [.tracking, .linked, .notLinked])
        #expect(preview.groups[1].lines.map(\.category) == [.identifiers, .purchases])
        #expect(preview.groups[1].lines.first?.typeNames == "User ID")
        #expect(preview.groups[2].lines.first?.types == [.crash])
    }

    @Test func noAnswerYetIsNotDataNotCollected() {
        #expect(!PrivacyWorksheet().labelPreview.isAnswered)
        #expect(!PrivacyWorksheet().labelPreview.isDataNotCollected)
    }

    @Test func theFiltersShowWhatTheySay() {
        var worksheet = Support.proposed([
            (.userId, Support.suggestion(Support.collected(linked: true))),
            (.coarseLocation, Support.suggestion(Support.collected(), confidence: .low)),
        ])
        worksheet.edit(.crash, to: Support.collected())
        worksheet.ask(Support.question(affects: [.userId]), at: Support.date)
        #expect(worksheet.shows(.crash, under: .all, showingAll: false))
        #expect(!worksheet.shows(.email, under: .all, showingAll: false))
        #expect(worksheet.shows(.email, under: .all, showingAll: true))
        #expect(!worksheet.shows(.crash, under: .unreviewed, showingAll: true))
        #expect(worksheet.shows(.coarseLocation, under: .lowConfidence, showingAll: false))
        #expect(!worksheet.shows(.userId, under: .lowConfidence, showingAll: false))
        #expect(worksheet.shows(.userId, under: .openQuestions, showingAll: false))
        #expect(worksheet.lowConfidenceCount == 1)
    }

    @Test func theOverviewSummaryReadsTheWorksheet() {
        var worksheet = Support.proposed([(.userId, Support.suggestion(Support.collected(linked: true)))])
        worksheet.ask(Support.question(), at: Support.date)
        worksheet.finishScan(at: Support.date)
        let summary = AppInformationSummary.Privacy(worksheet: worksheet)
        #expect(summary.status == .inProgress)
        #expect(summary.openQuestionCount == 1)
        #expect(summary.lastScanAssistant == Support.client)
        #expect(summary.lastScanDate == Support.date)
        #expect(!summary.isWorksheetDone)
    }
}
