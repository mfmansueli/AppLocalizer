//
//  PrivacySummaryWriterTests.swift
//  AppLocalizerTests
//

import Foundation
import Testing
@testable import AppLocalizer

/// The summary Export… writes for the team: reviewed answers with their
/// reasons and the open questions, as Markdown and as a PDF.
@Suite("PrivacySummaryWriter")
struct PrivacySummaryWriterTests {
    private typealias Support = PrivacyTestSupport

    private var worksheet: PrivacyWorksheet {
        var worksheet = Support.proposed([
            (.userId, Support.suggestion(Support.collected(linked: true))),
            (.crash, Support.suggestion(Support.collected())),
        ])
        worksheet.acceptCollects()
        worksheet.accept(.userId)
        worksheet.ask(Support.question(), at: Support.date)
        worksheet.answerQuestion("q1", with: false)
        return worksheet
    }

    @Test func theMarkdownHasReviewedAnswersOnly() {
        let markdown = PrivacySummaryWriter(appName: "Lumen Journal", worksheet: worksheet, date: Support.date).markdown()
        #expect(markdown.hasPrefix("# Lumen Journal · App Privacy answers"))
        #expect(markdown.contains("## Identifiers · User ID"))
        #expect(markdown.contains("Why: Because the code says so."))
        #expect(!markdown.contains("Crash Data"))
        #expect(markdown.contains("Does the support backend keep the email address? → No"))
    }

    @Test func thePDFIsAPDF() {
        let markdown = PrivacySummaryWriter(appName: "Lumen Journal", worksheet: worksheet, date: Support.date).markdown()
        let pdf = PrivacySummaryPDFWriter.pdf(from: markdown)
        #expect(pdf.starts(with: Data("%PDF".utf8)))
    }

    @Test func exportFileNames() {
        #expect(PrivacyExportFormat.fastlane.fileName(appName: "Lumen Journal") == "app_privacy_details.json")
        #expect(PrivacyExportFormat.markdown.fileName(appName: "Lumen Journal") == "Lumen Journal App Privacy.md")
        #expect(PrivacyExportFormat.pdf.contentType == .pdf)
    }
}
