//
//  AutopilotCenter+MomentMotion.swift
//  AppLocalizer
//

import Foundation

/// The App Preview's moments measured as they arrive: one that barely
/// moves goes back to the assistant once (`rerecord_moment`), so the video
/// isn't a slideshow; a second take that's still too still stays, and
/// Review says so.
extension AutopilotCenter {
    /// Measures what the first recording's App Preview would use, and asks
    /// again for what barely moves.
    func measureMotion(of recording: AutopilotRecording, file: URL, appID: StoreApp.ID) async {
        guard let run = runs[appID], run.pickRecordingTargets.first == recording.target else { return }
        let moments = run.moments(for: recording.target).filter { $0.suggested != false }
        var found: [String: AutopilotMomentMotion] = [:]
        for moment in moments {
            found[moment.screenID] = await readMotion(file, moment.start, Self.measuredEnd(of: moment))
        }
        guard !found.isEmpty else { return }
        update(appID) { run in
            run.noteMotion(found)
            let still = moments.map(\.screenID).filter { found[$0]?.isTooStill == true && run.motionRetakes?.contains($0) != true }
            for screenID in still { run.askAgainForMotion(screenID) }
            guard !still.isEmpty else { return }
            let names = still.map { run.plan.screen(id: $0)?.name ?? $0 }.formatted(.list(type: .and))
            run.appendLog(String(localized: "Almost nothing moves in \(names): asking to record again"), kind: .event, at: now())
        }
    }

    /// A new take's motion, kept for Review's check; it's never asked for a
    /// third time.
    func measureRetake(_ take: AutopilotRecording, file: URL, appID: StoreApp.ID) async {
        guard let run = runs[appID], run.pickRecordingTargets.first == take.target, let moment = take.markedMoments?.first,
              let motion = await readMotion(file, moment.start, Self.measuredEnd(of: moment)) else { return }
        update(appID) { $0.noteMotion([moment.screenID: motion]) }
    }

    /// The part of a moment the App Preview plays.
    private static func measuredEnd(of moment: AutopilotRecordingMoment) -> Double {
        min(moment.end, moment.start + AutopilotRecordingMoment.previewSeconds)
    }
}
