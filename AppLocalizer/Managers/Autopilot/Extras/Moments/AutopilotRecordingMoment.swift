//
//  AutopilotRecordingMoment.swift
//  AppLocalizer
//

import Foundation

/// A stretch of a recording that works in an App Preview: one of the
/// plan's screens, from when it has settled to just before the next, and
/// why. Claude Code marks them when it reports the recording; without its
/// marks, they come from when each screen shows up.
struct AutopilotRecordingMoment: Codable, Hashable, Sendable, Identifiable {
    /// The screen it shows: a recording has one moment a screen.
    var screenID: String
    /// Seconds from the recording's start.
    var start: Double
    var end: Double
    /// "The week chart animates in"; empty when Claude Code gave none.
    var reason: String
    /// Claude Code suggests it for the App Preview; nil leaves it to
    /// AppLocalizer (the first three).
    var suggested: Bool?

    var id: String { screenID }

    var seconds: Double { max(0, end - start) }

    /// How long each moment plays in the App Preview, and the end card.
    static let previewSeconds = 6.0

    /// AppLocalizer's suggestion when Claude Code gave none: the first
    /// three, a 24-second App Preview with the end card.
    static let suggestedCount = 3

    /// Moments from when each screen shows up, in the plan's order: from
    /// just after its mark, once it has settled, to just before the next
    /// mark (or the recording's end).
    static func marked(_ marks: [AutopilotRecordingMark], recordingSeconds: Double, screenIDs: [String]) -> [AutopilotRecordingMoment] {
        let inRecording = marks.filter { $0.seconds.isFinite && $0.seconds >= 0 && $0.seconds < recordingSeconds }
        let times = inRecording.map(\.seconds).sorted()
        var seen: Set<String> = []
        return screenIDs.compactMap { id in
            guard seen.insert(id).inserted, let mark = inRecording.filter({ $0.screenID == id }).min(by: { $0.seconds < $1.seconds }) else {
                return nil
            }
            let start = mark.seconds + AppPreviewCutter.settleSeconds
            let next = times.first { $0 > mark.seconds } ?? recordingSeconds
            let end = next < recordingSeconds ? next - AppPreviewCutter.leadOutSeconds : recordingSeconds
            guard end > start else { return nil }
            return AutopilotRecordingMoment(screenID: id, start: start, end: end, reason: "")
        }
    }
}
