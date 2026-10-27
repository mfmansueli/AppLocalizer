//
//  PrivacySummaryWriter.swift
//  AppLocalizer
//

import Foundation

/// The summary Export… saves for the team: every reviewed answer with its
/// reason, and the open questions with their answers, as Markdown.
/// `PrivacySummaryPDFWriter` lays the same text out as a PDF.
struct PrivacySummaryWriter {
    var appName: String
    var worksheet: PrivacyWorksheet
    var date: Date

    func markdown() -> String {
        let answers = worksheet.reviewedAnswers
        var lines = ["# " + String(localized: "\(appName) · App Privacy answers"), "", intro, ""]
        let collects = answers.collects.map { $0 ? String(localized: "Yes") : String(localized: "No") } ?? String(localized: "Not answered")
        lines += [String(localized: "Collects data: \(collects)"), ""]
        for type in answers.collectedTypes {
            guard let answer = answers.collected[type] else { continue }
            let purposes = answer.sortedPurposes.map(\.title).joined(separator: ", ")
            let linked = answer.linked ? String(localized: "Yes") : String(localized: "No")
            let tracking = answer.tracking ? String(localized: "Yes") : String(localized: "No")
            let why = worksheet[type]?.suggestion?.rationale ?? String(localized: "Answered by the team")
            lines += [
                "## \(type.category.name) · \(type.name)",
                "- " + String(localized: "Purposes: \(purposes)"),
                "- " + String(localized: "Linked to the user: \(linked) · Tracking: \(tracking)"),
                "- " + String(localized: "Why: \(why)"),
                "",
            ]
        }
        if !worksheet.questions.isEmpty {
            lines.append(String(localized: "Open questions and answers:"))
            for question in worksheet.questions {
                let answer = question.answer.map { $0 ? String(localized: "Yes") : String(localized: "No") } ?? String(localized: "unanswered")
                lines.append("- \(question.question) → \(answer)")
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// "Worksheet from AppLocalizer, Oct 26, 2026. Based on a scan of
    /// northpier/lumen @ 4f2c91a by Claude Code, reviewed by the team."
    private var intro: String {
        let day = date.formatted(date: .abbreviated, time: .omitted)
        guard let scan = worksheet.lastScan else {
            return String(localized: "Worksheet from AppLocalizer, \(day). Answered by the team.")
        }
        let source = scan.source ?? String(localized: "the project")
        return String(localized: "Worksheet from AppLocalizer, \(day). Based on a scan of \(source) by \(scan.assistant), reviewed by the team.")
    }
}
