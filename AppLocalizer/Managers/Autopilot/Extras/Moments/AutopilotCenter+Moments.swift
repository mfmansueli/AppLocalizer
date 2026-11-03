//
//  AutopilotCenter+Moments.swift
//  AppLocalizer
//

import Foundation

/// Pick's App Preview moments: which go in, and Record Again, which Claude
/// Code does before the design step with `rerecord_moment`.
extension AutopilotCenter {
    /// Checks or unchecks a moment for the App Preview, in every recording.
    func setMoment(appID: StoreApp.ID, screenID: String, chosen: Bool) {
        guard let run = runs[appID], run.stage == .pick, run.pickableMoments.contains(where: { $0.screenID == screenID }) else { return }
        update(appID) { $0.setMoment(screenID, chosen: chosen) }
    }

    /// The person asked for a moment again: Claude Code records it before
    /// the design step; the rest of the recording stays.
    func askToRecordAgain(appID: StoreApp.ID, screenID: String) {
        guard let run = runs[appID], [.pick, .design, .choose].contains(run.stage),
              run.pickableMoments.contains(where: { $0.screenID == screenID }) else { return }
        let name = run.plan.screen(id: screenID)?.name ?? screenID
        update(appID) { run in
            run.askToRecordAgain(screenID)
            run.appendLog(String(localized: "Asked to record “\(name)” again before the design step"), kind: .event, at: now())
            // Past Pick, the assistant has work again.
            if run.stage != .pick { run.handedBackAt = now() }
        }
    }

    /// A new take of one moment (`rerecord_moment`): it stands in for that
    /// moment of the device's recording in the App Preview.
    @discardableResult
    func receiveRetake(
        appID: StoreApp.ID, upload: AutopilotRecordingUpload, target: AutopilotRecordingTarget, retake: AutopilotMomentRetake
    ) throws -> AutopilotRecording {
        let screenID = retake.screenID
        guard let run = runs[appID], [.pick, .design, .choose].contains(run.stage) else {
            throw AutopilotError(String(localized: "Moments are recorded again before the design step. Call next_step to see what AppLocalizer wants."))
        }
        guard run.momentRetakes?.contains(screenID) == true else {
            throw AutopilotError(String(localized: "Nobody asked to record this moment again. Call list_recording_moments to see what’s wanted."))
        }
        guard run.pickRecordingTargets.contains(target) else {
            let wanted = run.pickRecordingTargets.map { "\($0.displayType.mcpValue) \($0.locale)" }
            throw AutopilotError(String(localized: "This moment is recorded again on \(wanted.formatted(.list(type: .and))) only."))
        }
        try Self.checkRecording(upload.file, for: target.displayType)
        let seconds = upload.file.seconds
        let start = min(max(retake.start ?? AppPreviewCutter.settleSeconds, 0), max(0, seconds - 0.5))
        let end = min(max(retake.end ?? seconds, start + 0.5), seconds)
        let moment = AutopilotRecordingMoment(screenID: screenID, start: start, end: end, reason: retake.reason ?? "", suggested: true)
        let take = AutopilotRecording(
            id: makeID(), target: target, fileID: upload.file.id, pixelSize: upload.file.pixelSize, seconds: seconds,
            marks: [AutopilotRecordingMark(screenID: screenID, seconds: start)], receivedAt: now(), markedMoments: [moment], retakeOf: screenID
        )
        recordingUploads[upload.id] = nil
        let name = run.plan.screen(id: screenID)?.name ?? screenID
        update(appID) { run in
            run.addRetake(take)
            run.appendLog(String(localized: "“\(name)” recorded again on \(target.displayType.title) (\(target.locale))"), kind: .event, at: now())
        }
        return take
    }
}
