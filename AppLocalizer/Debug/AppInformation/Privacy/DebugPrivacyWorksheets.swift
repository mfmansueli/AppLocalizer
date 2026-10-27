//
//  DebugPrivacyWorksheets.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen Journal's App Privacy worksheet in each `priv-*` scene's state,
/// built by running Claude Code's suggestions through the worksheet's own
/// rules, so the scenes show what the app would.
enum DebugPrivacyWorksheets {
    /// The overview's: in review, marked published on Sep 12, 2026 with
    /// different answers, so it reads Out of date.
    static var overview: PrivacyWorksheet {
        var worksheet = review
        worksheet.publication = PrivacyPublication(
            date: DebugPrivacyScan.date(2026, 9, 12),
            snapshot: PrivacyReviewedAnswers(collects: true, collected: [:])
        )
        return worksheet
    }

    /// The first five suggestions arrived; the scan is still running.
    static func scanning(at date: Date = .now) -> PrivacyWorksheet {
        var worksheet = PrivacyWorksheet()
        var details = DebugPrivacyScan.first
        details.sdks = Array(details.sdks.prefix(9))
        details.manifestsRead = Array(details.manifestsRead.prefix(3))
        worksheet.recordScanDetails(details, at: date)
        for (type, suggestion) in DebugPrivacySuggestions.first.prefix(5) {
            worksheet.propose(suggestion, for: type, at: date)
        }
        return worksheet
    }

    /// The first scan done: twelve suggestions and three open questions;
    /// User ID, Purchase History and Crash Data accepted, and Yes to the
    /// first question.
    static var review: PrivacyWorksheet {
        var worksheet = scanned()
        for type in [PrivacyDataType.userId, .purchases, .crash] {
            worksheet.accept(type)
        }
        worksheet.acceptCollects()
        return worksheet
    }

    /// The person said Device ID is linked; Claude Code says it isn't.
    static var conflict: PrivacyWorksheet {
        var worksheet = review
        var entry = PrivacyTypeEntry.yours(PrivacyAnswer(collected: true, purposes: [.analytics], linked: true))
        entry.suggestion = worksheet[.deviceId]?.suggestion
        entry.conflict = worksheet[.deviceId]?.suggestion
        worksheet[.deviceId] = entry
        return worksheet
    }

    /// Everything reviewed and every question answered: done.
    static var done: PrivacyWorksheet {
        var worksheet = review
        worksheet.answerQuestion("q1", with: true)
        worksheet.answerQuestion("q2", with: false)
        worksheet.answerQuestion("q3", with: false)
        for type in PrivacyDataType.allCases {
            worksheet.accept(type)
        }
        return worksheet
    }

    /// Done, but Other Diagnostic Data edited to not collected, which
    /// Sentry's manifest declares.
    static var mismatch: PrivacyWorksheet {
        var worksheet = done
        worksheet.edit(.otherDiagnostics, to: .notCollected)
        return worksheet
    }

    /// Done, with the first steps ticked.
    static var checklist: PrivacyWorksheet {
        var worksheet = done
        for step in worksheet.checklistSteps where ["s1", "s2", "d-userId"].contains(step.id) {
            worksheet.setChecked(step, true)
        }
        return worksheet
    }

    /// Done and marked published on Oct 26, 2026.
    static var published: PrivacyWorksheet {
        var worksheet = done
        worksheet.markPublished(at: DebugPrivacyScan.firstScanDate)
        return worksheet
    }

    /// Published, then a rescan on Nov 9 found Mixpanel and suggests
    /// Coarse Location (asking the three questions again, already
    /// answered): out of date.
    static var rescan: PrivacyWorksheet {
        var worksheet = published
        let date = DebugPrivacyScan.secondScanDate
        worksheet.recordScanDetails(DebugPrivacyScan.second, at: date)
        let (type, suggestion) = DebugPrivacySuggestions.coarseLocation
        worksheet.propose(suggestion, for: type, at: date)
        for (type, suggestion) in DebugPrivacySuggestions.first {
            worksheet.propose(suggestion, for: type, at: date)
        }
        for question in DebugPrivacySuggestions.questions {
            worksheet.ask(question, at: date)
        }
        worksheet.finishScan(at: date)
        return worksheet
    }

    /// A fastlane `app_privacy_details.json` with five data types, for the
    /// import scene.
    static var fastlaneFile: Data {
        let answers = PrivacyReviewedAnswers(collects: true, collected: [
            .crash: PrivacyAnswer(collected: true, purposes: [.appFunctionality]),
            .interaction: PrivacyAnswer(collected: true, purposes: [.analytics]),
            .userId: PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true),
            .purchases: PrivacyAnswer(collected: true, purposes: [.appFunctionality], linked: true),
            .deviceId: PrivacyAnswer(collected: true, purposes: [.analytics], linked: true),
        ])
        return (try? PrivacyFastlaneCoder.encode(answers)) ?? Data()
    }

    /// The first scan, finished, nothing reviewed.
    private static func scanned() -> PrivacyWorksheet {
        var worksheet = PrivacyWorksheet()
        let date = DebugPrivacyScan.firstScanDate
        worksheet.recordScanDetails(DebugPrivacyScan.first, at: date)
        for (type, suggestion) in DebugPrivacySuggestions.first {
            worksheet.propose(suggestion, for: type, at: date)
        }
        for question in DebugPrivacySuggestions.questions {
            worksheet.ask(question, at: date)
        }
        worksheet.finishScan(at: date)
        return worksheet
    }
}
#endif
