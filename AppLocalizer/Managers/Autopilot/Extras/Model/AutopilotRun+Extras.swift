//
//  AutopilotRun+Extras.swift
//  AppLocalizer
//

import Foundation

/// The App Preview's recordings in a run: which have arrived, which the
/// assistant couldn't make, and which are left.
extension AutopilotRun {
    func recording(for target: AutopilotRecordingTarget) -> AutopilotRecording? {
        recordings?.last { $0.target == target }
    }

    func isSkipped(_ target: AutopilotRecordingTarget) -> Bool {
        recordingSkips?.contains { $0.target == target } == true
    }

    /// Recordings still to make, in the plan's order.
    var remainingRecordings: [AutopilotRecordingTarget] {
        plan.recordingTargets.filter { recording(for: $0) == nil && !isSkipped($0) }
    }

    /// The recording an App Preview is made from: its language's, else the
    /// primary language's on the same device.
    func previewRecording(for target: AutopilotRecordingTarget) -> AutopilotRecording? {
        recording(for: target) ?? recording(for: AutopilotRecordingTarget(displayType: target.displayType, locale: plan.primaryLocale))
    }

    /// Records a recording, replacing an earlier one of the same device and
    /// language, and clears a skip there.
    mutating func addRecording(_ recording: AutopilotRecording) {
        var all = (recordings ?? []).filter { $0.target != recording.target }
        all.append(recording)
        recordings = all
        recordingSkips = recordingSkips?.filter { $0.target != recording.target }
        if recordingSkips?.isEmpty == true { recordingSkips = nil }
    }

    /// The recordings the assistant couldn't make, in the order reported.
    var skippedRecordings: [AutopilotRecordingSkip] { recordingSkips ?? [] }

    /// Record Again: the skipped recordings are left to make once more.
    mutating func recordSkippedAgain() {
        recordingSkips = nil
    }

    /// The assistant couldn't make a recording: the run goes on without it.
    mutating func skipRecording(_ skip: AutopilotRecordingSkip) {
        recordingSkips = (recordingSkips ?? []).filter { $0.target != skip.target } + [skip]
    }
}
