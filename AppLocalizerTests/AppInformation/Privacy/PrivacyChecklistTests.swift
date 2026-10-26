//
//  PrivacyChecklistTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// "Fill in App Store Connect": the steps in the questionnaire's order,
/// ticks that lapse when the answer behind them changes, and Mark as
/// Published keeping a snapshot.
@Suite("PrivacyWorksheet checklist")
struct PrivacyChecklistTests {
    private typealias Support = PrivacyTestSupport

    private var worksheet: PrivacyWorksheet {
        Support.answered([
            .email: Support.collected(linked: true),
            .userId: Support.collected(linked: true),
            .crash: Support.collected(),
        ])
    }

    @Test func theStepsFollowTheQuestionnaire() throws {
        let steps = worksheet.checklistSteps
        #expect(steps.map(\.number) == ["1", "2", "3.1", "3.2", "3.3", "4"])
        #expect(steps[0].body == "Yes, we collect data from this app")
        #expect(steps[1].body == "Contact Info: Email Address\nIdentifiers: User ID\nDiagnostics: Crash Data")
        let email = try #require(steps.first { $0.id == "d-email" })
        #expect(email.isTypeStep)
        #expect(email.body == "Purposes: App Functionality\nLinked to the user’s identity: Yes\nUsed for tracking: No")
        #expect(steps.last?.canCopy == false)
    }

    @Test func noDataCollectedIsTwoSteps() {
        var worksheet = PrivacyWorksheet()
        worksheet.setCollects(false)
        #expect(worksheet.checklistSteps.map(\.number) == ["1", "2"])
        #expect(worksheet.checklistSteps.first?.body == "No, we do not collect data from this app")
    }

    @Test func aTickLapsesWhenTheAnswerChanges() throws {
        var worksheet = worksheet
        let step = try #require(worksheet.checklistSteps.first { $0.id == "d-userId" })
        worksheet.setChecked(step, true)
        #expect(worksheet.checkedStepCount == 1)
        worksheet.edit(.userId, to: Support.collected([.analytics], linked: true))
        #expect(worksheet.checkedStepCount == 0)
        let changed = try #require(worksheet.checklistSteps.first { $0.id == "d-userId" })
        #expect(!worksheet.isChecked(changed))
        worksheet.setChecked(changed, true)
        worksheet.setChecked(changed, false)
        #expect(worksheet.checkedStepCount == 0)
    }

    @Test func markingPublishedKeepsTheReviewedAnswers() {
        var worksheet = worksheet
        for step in worksheet.checklistSteps {
            worksheet.setChecked(step, true)
        }
        #expect(worksheet.allStepsChecked)
        worksheet.markPublished(at: Support.date)
        #expect(worksheet.publication?.snapshot == worksheet.reviewedAnswers)
        #expect(worksheet.status.publishedDate == Support.date)
    }
}
