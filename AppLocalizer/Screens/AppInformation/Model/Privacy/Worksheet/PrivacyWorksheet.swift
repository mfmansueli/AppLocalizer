//
//  PrivacyWorksheet.swift
//  AppLocalizer
//

import Foundation

/// One app's App Privacy worksheet. App Store Connect has no API for the
/// questionnaire, so this is kept on this Mac (`PrivacyWorksheetStore`):
/// the answers, the assistants' suggestions and evidence, open questions,
/// scans, the checklist's ticks and the published snapshot.
///
/// Rules (the design's decisions):
/// - Unreviewed suggestions don't count anywhere: not in the label
///   preview, the checklist, the export or the published snapshot.
/// - Open questions block "done"; answering one applies its effect to the
///   types it affects.
/// - A rejected suggestion becomes "not collected", the person's, so the
///   cross-check can still catch a manifest that disagrees.
/// - Out of date: after Mark as Published, the reviewed answers differ from
///   the snapshot, or something new waits for review.
///
/// The edits are in `PrivacyWorksheet+Review.swift`, the assistants'
/// suggestions in `+Proposals.swift`, what it adds up to in `+Status.swift`
/// and the checklist in `+Checklist.swift`.
struct PrivacyWorksheet: Hashable, Codable, Sendable {
    /// "Do you or your third-party partners collect data from this app?"
    var collects: PrivacyCollectsAnswer?
    /// Data types someone answered; the rest read as not collected.
    var entries: [PrivacyDataType: PrivacyTypeEntry] = [:]
    var questions: [PrivacyOpenQuestion] = []
    /// Finished scans, oldest first.
    var scans: [PrivacyScan] = []
    var runningScan: PrivacyRunningScan?
    /// The SDKs whose privacy manifests declare each type, from the
    /// assistants' evidence, for the cross-check.
    var manifestDeclarations: [PrivacyDataType: [String]] = [:]
    /// Why a type a manifest declares isn't collected after all ("Not
    /// Collected, Explain…").
    var explanations: [PrivacyDataType: String] = [:]
    /// The checklist steps the person ticked.
    var checkedSteps: Set<String> = []
    var publication: PrivacyPublication?
    /// Started from scratch, from fastlane or by hand, without a scan.
    var isStarted = false

    init() {}

    /// Decoded field by field in `PrivacyWorksheet+Coding.swift`.
    enum CodingKeys: String, CodingKey {
        case collects
        case entries
        case questions
        case scans
        case runningScan
        case manifestDeclarations
        case explanations
        case checkedSteps
        case publication
        case isStarted
    }

    /// The row for `type`, if anyone answered it.
    subscript(type: PrivacyDataType) -> PrivacyTypeEntry? {
        get { entries[type] }
        set { entries[type] = newValue }
    }

    var openQuestions: [PrivacyOpenQuestion] {
        questions.filter(\.isOpen)
    }

    /// The open question about `type`, if one is waiting.
    func openQuestion(about type: PrivacyDataType) -> PrivacyOpenQuestion? {
        openQuestions.first { $0.affects.contains(type) }
    }

    var lastScan: PrivacyScan? { scans.last }

    /// The running scan, unless it went quiet before `date`.
    func activeScan(at date: Date) -> PrivacyRunningScan? {
        runningScan.flatMap { $0.isActive(at: date) ? $0 : nil }
    }
}
