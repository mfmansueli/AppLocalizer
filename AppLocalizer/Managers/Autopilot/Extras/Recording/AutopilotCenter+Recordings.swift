//
//  AutopilotCenter+Recordings.swift
//  AppLocalizer
//

import Foundation

/// The App Preview's recordings: the assistant records the plan's screens
/// in the Simulator during the capture run, sends each video to the upload
/// link and reports when each screen appears, or says why it couldn't.
extension AutopilotCenter {
    /// A video arrived at the upload link; `report_recording` names it by
    /// the returned ID.
    func registerRecordingUpload(_ file: RecordingFile, for run: AutopilotRun) -> AutopilotRecordingUpload {
        let upload = AutopilotRecordingUpload(id: "rec-" + makeID().prefix(12), appID: run.appID, runID: run.id, file: file, receivedAt: now())
        recordingUploads[upload.id] = upload
        return upload
    }

    /// Records the recording of `target`, replacing an earlier one, and
    /// moves on when it was the last thing to capture.
    func receiveRecording(
        appID: StoreApp.ID, upload: AutopilotRecordingUpload, target: AutopilotRecordingTarget, marks: [AutopilotRecordingMark],
        moments: [AutopilotRecordingMoment] = [], context: AutopilotContext
    ) async throws -> AutopilotRecording {
        let run = try recordingRun(appID, target: target)
        try Self.checkRecording(upload.file, for: target.displayType)
        let known = Set(run.plan.screens.map(\.id))
        let seconds = upload.file.seconds
        let moments = moments.filter { known.contains($0.screenID) && $0.start >= 0 && $0.start < seconds && $0.end > $0.start }
        // Moments say when each screen shows up too.
        let sent = marks.isEmpty
            ? moments.map { AutopilotRecordingMark(screenID: $0.screenID, seconds: max(0, $0.start - AppPreviewCutter.settleSeconds)) }
            : marks
        let marks = sent.filter { known.contains($0.screenID) && $0.seconds >= 0 && $0.seconds < seconds }
            .sorted { $0.seconds < $1.seconds }
        guard !marks.isEmpty else {
            let ids = run.plan.screens.map(\.id).joined(separator: ", ")
            throw AutopilotError(String(localized: "Say when each screen appears in the recording: marks with the plan’s screen IDs (\(ids)) and the second each one shows up."))
        }
        let recording = AutopilotRecording(
            id: makeID(), target: target, fileID: upload.file.id, pixelSize: upload.file.pixelSize, seconds: upload.file.seconds,
            marks: marks, receivedAt: now(), markedMoments: moments.isEmpty ? nil : moments
        )
        recordingUploads[upload.id] = nil
        update(appID) { run in
            run.addRecording(recording)
            run.appendLog(Self.recordingLogLine(recording, screens: marks.count), kind: .event, at: now())
        }
        await advance(appID, context: context)
        return recording
    }

    /// The assistant couldn't record `target`: the run goes on without it.
    func skipRecording(appID: StoreApp.ID, target: AutopilotRecordingTarget, reason: String, context: AutopilotContext) async throws {
        _ = try recordingRun(appID, target: target)
        update(appID) { run in
            run.skipRecording(AutopilotRecordingSkip(target: target, reason: reason, reportedAt: now()))
            run.appendLog(String(localized: "App Preview recording on \(target.displayType.title) (\(target.locale)) left out: \(reason)"), kind: .event, at: now())
        }
        await advance(appID, context: context)
    }

    /// The run, while it captures and wants this recording.
    private func recordingRun(_ appID: StoreApp.ID, target: AutopilotRecordingTarget) throws -> AutopilotRun {
        guard let run = runs[appID], run.stage == .capture || run.stage == .waiting else {
            throw AutopilotError(String(localized: "The run isn’t capturing now. Call next_step to see what AppLocalizer wants."))
        }
        guard run.plan.recordingTargets.contains(target) else {
            let wanted = run.plan.recordingTargets.map { "\($0.displayType.mcpValue) \($0.locale)" }
            throw AutopilotError(wanted.isEmpty
                ? String(localized: "This run makes no App Preview, so it takes no recording.")
                : String(localized: "This run records \(wanted.formatted(.list(type: .and))) only."))
        }
        return run
    }

    /// "simctl io booted recordVideo --codec h264 → preview/en-US/iPhone.mov
    /// · plan walkthrough · 38 s".
    static func recordingLogLine(_ recording: AutopilotRecording, screens _: Int) -> String {
        let file = "preview/\(recording.target.locale)/\(recording.target.displayType.shortTitle).mov"
        let seconds = Int(recording.seconds.rounded())
        return String(localized: "simctl io booted recordVideo --codec h264 → \(file) · plan walkthrough · \(seconds) s")
    }

    /// The shortest recording an App Preview can be cut from.
    static let shortestRecording = 6.0

    /// A recording is the device's screen, either way up, and long enough
    /// to cut an App Preview from.
    static func checkRecording(_ file: RecordingFile, for display: ScreenshotDisplayType) throws {
        let expected = display.portraitPixelSize
        let ratio = Double(min(file.pixelSize.width, file.pixelSize.height)) / Double(max(file.pixelSize.width, file.pixelSize.height))
        let wanted = Double(min(expected.width, expected.height)) / Double(max(expected.width, expected.height))
        guard abs(ratio - wanted) < 0.02 else {
            throw AutopilotError(String(localized: "A \(file.pixelSize.title) recording isn’t \(display.title)’s screen (\(expected.title)). Record on \(display.deviceName) with xcrun simctl io booted recordVideo."))
        }
        guard file.seconds >= shortestRecording else {
            throw AutopilotError(String(localized: "The recording is \(Int(file.seconds.rounded())) s: walk through every screen of the plan, about 4 s on each."))
        }
    }
}
