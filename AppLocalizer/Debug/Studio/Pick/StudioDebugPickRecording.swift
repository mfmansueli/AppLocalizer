//
//  StudioDebugPickRecording.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 31's raw recording: 38 seconds of Lumen's mock captures, with
/// the five moments Claude Code marked (the first three suggested), saved
/// in the Recordings folder so Pick's player plays it. Made once per
/// device and language.
@MainActor
enum StudioDebugPickRecording {
    /// Bump when the recording is drawn differently, to make it again.
    private static let version = 1
    static let seconds = 38.0

    /// The board's moments: screen slot, seconds, why.
    static let moments: [(slot: Int, seconds: ClosedRange<Double>, reason: String)] = [
        (0, 2...8, "The prompt card fills in; calm, no typing"),
        (1, 9...15, "The week chart animates in"),
        (2, 16...22, "Types “lake”, results appear"),
        (3, 24...30, "Photos load in; a little slow"),
        (4, 31...36, "Face ID prompt; little to see"),
    ]

    static func fileID(for target: AutopilotRecordingTarget) -> String {
        "debug-pick\(version)-\(target.displayType.mcpValue)-\(target.locale)"
    }

    /// The run's recordings, each with the board's moments; `shown` ones
    /// get a real file (`write`).
    static func addRecordings(to run: inout AutopilotRun) {
        let screens = run.plan.screens
        let received = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 4)
        for target in run.plan.recordingTargets {
            let marked = moments.filter { screens.indices.contains($0.slot) }.map { moment in
                AutopilotRecordingMoment(
                    screenID: screens[moment.slot].id, start: moment.seconds.lowerBound, end: moment.seconds.upperBound,
                    reason: moment.reason, suggested: moment.slot < 3
                )
            }
            run.addRecording(AutopilotRecording(
                id: "rec-\(target.displayType.mcpValue)-\(target.locale)", target: target, fileID: fileID(for: target),
                pixelSize: target.displayType.portraitPixelSize, seconds: seconds,
                marks: marked.map { AutopilotRecordingMark(screenID: $0.screenID, seconds: max(0, $0.start - 1)) }, receivedAt: received,
                markedMoments: marked
            ))
        }
    }

    /// Writes `targets`' recordings if they aren't there yet, then loads
    /// the one Pick shows.
    static func write(_ targets: [AutopilotRecordingTarget], run: AutopilotRun, model: ScreenshotsViewModel, then: (@MainActor () -> Void)? = nil) async {
        for target in targets {
            guard let recording = run.recording(for: target) else { continue }
            let url = model.services.recordingURL(recording.fileID, for: model.app)
            guard !FileManager.default.fileExists(atPath: url.path) else { continue }
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let size = PixelSize(width: target.displayType.portraitPixelSize.width / 2, height: target.displayType.portraitPixelSize.height / 2)
            let mock = StudioDebugPreviewMovies.Recording(url: url, size: size, seconds: seconds, marks: recording.marks)
            do {
                try await StudioDebugPreviewMovies.writeRecording(mock, display: target.displayType, locale: target.locale, run: run, model: model)
            } catch {
                print("StudioDebugPickRecording: \(target.displayType.title) \(target.locale): \(error.localizedDescription)")
            }
        }
        if let shown = model.studio.run { model.studio.loadPickRecording(shown) }
        then?()
    }
}
#endif
