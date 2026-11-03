//
//  AutopilotRecording+Moments.swift
//  AppLocalizer
//

import Foundation

extension AutopilotRecording {
    /// Its moments in the plan's order: Claude Code's marks, else one a
    /// screen from when each shows up.
    func moments(screenIDs: [String]) -> [AutopilotRecordingMoment] {
        guard let marked = markedMoments, !marked.isEmpty else {
            return AutopilotRecordingMoment.marked(marks, recordingSeconds: seconds, screenIDs: screenIDs)
        }
        let order = Dictionary(screenIDs.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return marked
            .filter { order[$0.screenID] != nil && $0.end > $0.start && $0.start < seconds }
            .map { moment in
                var moment = moment
                moment.end = min(moment.end, seconds)
                return moment
            }
            .sorted { (order[$0.screenID] ?? 0) < (order[$1.screenID] ?? 0) }
    }
}
