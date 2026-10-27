//
//  PrivacyRunningScan.swift
//  AppLocalizer
//

import Foundation

/// A scan an assistant has started and not finished: it read the
/// questionnaire, and may have sent some suggestions already. The activity
/// row shows it until the last `propose_privacy_answers` call, or until it
/// goes quiet for half an hour.
struct PrivacyRunningScan: Hashable, Codable, Sendable {
    var assistant: String
    var startedAt: Date
    var lastActivity: Date
    /// What the assistant sent so far, merged across calls.
    var scan: PrivacyScan?
    /// Data types this scan suggested something new or different for.
    var changedTypes: Set<PrivacyDataType> = []
    /// Every data type it answered, and the questions it asked.
    var answeredTypes: Set<PrivacyDataType> = []
    var questionIDs: Set<String> = []

    static let quietLimit: TimeInterval = 30 * 60

    /// Still running at `date`: heard from in the last half hour.
    func isActive(at date: Date) -> Bool {
        date.timeIntervalSince(lastActivity) < Self.quietLimit
    }
}
