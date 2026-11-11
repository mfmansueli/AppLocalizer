//
//  PrivacyWorksheet+Status.swift
//  AppLocalizer
//

import Foundation

// What the worksheet adds up to: the answers that count, what still needs
// the person, whether it's done, and where it stands against App Store
// Connect.
extension PrivacyWorksheet {
    /// Reviewed answers only; unreviewed suggestions don't count anywhere.
    var reviewedAnswers: PrivacyReviewedAnswers {
        let collectsValue = collects?.countedValue
        var collected: [PrivacyDataType: PrivacyAnswer] = [:]
        if collectsValue == true {
            for (type, entry) in entries {
                if let answer = entry.countedAnswer, answer.collected {
                    collected[type] = answer
                }
            }
        }
        return PrivacyReviewedAnswers(collects: collectsValue, collected: collected)
    }

    /// Something was answered, suggested, scanned or started.
    var hasContent: Bool {
        isStarted || collects != nil || !entries.isEmpty || !scans.isEmpty || runningScan != nil || !questions.isEmpty
    }

    // MARK: - Counts

    /// Unreviewed suggestions, including the first question.
    var unreviewedCount: Int {
        entries.values.count { $0.status == .unreviewed } + (collects?.status == .unreviewed ? 1 : 0)
    }

    var lowConfidenceCount: Int {
        entries.values.count { $0.status == .unreviewed && $0.suggestion?.confidence == .low }
    }

    var conflictTypes: [PrivacyDataType] {
        PrivacyDataType.allCases.filter { entries[$0]?.conflict != nil }
    }

    /// Collected types without a purpose: "Pick at least one purpose".
    var missingPurposeTypes: [PrivacyDataType] {
        PrivacyDataType.allCases.filter { entries[$0]?.answer.isMissingPurpose == true }
    }

    /// Whether `type` shows under `filter`. All shows the answered types,
    /// or every type with Show All.
    func shows(_ type: PrivacyDataType, under filter: PrivacyWorksheetFilter, showingAll: Bool) -> Bool {
        let entry = entries[type]
        switch filter {
        case .all: return showingAll || entry != nil
        case .unreviewed: return entry?.status == .unreviewed
        case .lowConfidence: return entry?.status == .unreviewed && entry?.suggestion?.confidence == .low
        case .openQuestions: return openQuestion(about: type) != nil
        }
    }

    // MARK: - Done

    /// Done: the first question answered and reviewed, nothing unreviewed,
    /// no open question, no conflict, and a purpose for every collected
    /// type.
    var isDone: Bool {
        collects?.countedValue != nil && unreviewedCount == 0 && openQuestions.isEmpty && conflictTypes.isEmpty
            && missingPurposeTypes.isEmpty
    }

    /// What keeps the checklist closed, e.g. "Finish the worksheet first: 3
    /// unreviewed, 2 open questions." Nil when it's done.
    var blockedReason: String? {
        guard !isDone else { return nil }
        var parts: [String] = []
        if collects == nil { parts.append(String(localized: "the first question")) }
        if unreviewedCount > 0 { parts.append(String(localized: "\(unreviewedCount) unreviewed")) }
        if !openQuestions.isEmpty {
            parts.append(openQuestions.count == 1 ? String(localized: "1 open question") : String(localized: "\(openQuestions.count) open questions"))
        }
        if !conflictTypes.isEmpty {
            parts.append(conflictTypes.count == 1 ? String(localized: "1 conflict") : String(localized: "\(conflictTypes.count) conflicts"))
        }
        if !missingPurposeTypes.isEmpty { parts.append(String(localized: "\(missingPurposeTypes.count) without a purpose")) }
        let list = parts.formatted(.list(type: .and, width: .narrow))
        return String(localized: "Finish the worksheet first: \(list).")
    }

    /// Not started → In progress → Done → Marked published, or Out of
    /// date once the reviewed answers differ from the published snapshot
    /// or something new waits for review.
    var status: PrivacyWorksheetStatus {
        if let publication {
            let changed = reviewedAnswers != publication.snapshot || unreviewedCount > 0 || !conflictTypes.isEmpty
            return changed ? .outOfDate(publication.date) : .published(publication.date)
        }
        if !hasContent { return .notStarted }
        return isDone ? .done : .inProgress
    }

    // MARK: - Cross-check

    /// Types an SDK's privacy manifest declares that the person answered
    /// not collected, unless they explained why.
    var mismatches: [PrivacyManifestMismatch] {
        PrivacyDataType.allCases.compactMap { type in
            guard let sdks = manifestDeclarations[type], !sdks.isEmpty, explanations[type] == nil,
                  let entry = entries[type], entry.status.isReviewed, !entry.answer.collected
            else { return nil }
            return PrivacyManifestMismatch(sdk: sdks.formatted(.list(type: .and)), type: type)
        }
    }

    /// The label App Store Connect will show, from reviewed answers only.
    var labelPreview: PrivacyLabelPreview {
        PrivacyLabelPreview(answers: reviewedAnswers)
    }
}
