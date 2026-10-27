//
//  AppInformationSummary.swift
//  AppLocalizer
//

import Foundation

/// What the overview's App Information cards show for one app. Produced by
/// `AppInformationServices`.
struct AppInformationSummary: Hashable, Sendable {
    /// App Privacy at a glance. The API can't write App Privacy, so it
    /// comes from the worksheet kept on this Mac.
    struct Privacy: Hashable, Sendable {
        var status: PrivacyWorksheetStatus = .notStarted
        var isWorksheetDone = false
        var openQuestionCount = 0
        var lastScanDate: Date?
        /// e.g. "Claude Code".
        var lastScanAssistant: String?

        init() {}

        init(worksheet: PrivacyWorksheet) {
            status = worksheet.status
            isWorksheetDone = worksheet.isDone
            openQuestionCount = worksheet.openQuestions.count
            lastScanDate = worksheet.lastScan?.ranAt
            lastScanAssistant = worksheet.lastScan?.assistant
        }

        /// "Done", "In progress" or "Not started".
        var worksheetTitle: String {
            if isWorksheetDone { return String(localized: "Done") }
            return status == .notStarted ? String(localized: "Not started") : String(localized: "In progress")
        }
    }

    /// How many locales have each privacy URL.
    struct PrivacyURLs: Hashable, Sendable {
        var localeCount: Int
        var policyCount: Int
        var choicesCount: Int

        init(localeCount: Int, policyCount: Int, choicesCount: Int) {
            self.localeCount = localeCount
            self.policyCount = policyCount
            self.choicesCount = choicesCount
        }

        init(table: PrivacyURLsTable) {
            self.init(localeCount: table.locales.count, policyCount: table.policyCount, choicesCount: table.choicesCount)
        }

        /// Locales without a valid Privacy Policy URL.
        var missingPolicyCount: Int { max(0, localeCount - policyCount) }
    }

    /// e.g. "4+", "9+"; nil when no questionnaire has been answered.
    var ageRating: String?
    var privacy = Privacy()
    /// Nil when they couldn't be read.
    var privacyURLs: PrivacyURLs?
    /// Contact and notes are filled in.
    var isAppReviewComplete: Bool
}
