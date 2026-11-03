//
//  StudioDebugPick.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 31's scenes, "Pick the best captures":
/// - `st-pick-shots-video`: the Screenshots tab, best of 3 per screen,
///   with an App Preview recording too.
/// - `st-pick-alt`: you chose the Week screen's second attempt.
/// - `st-lb-pick`: the full-size viewer over Today's attempts, at the
///   second.
/// - `st-pick-duo`: iPhone Duo's inner and cover displays, side by side.
/// - `st-pick-rec`: the Recording tab with the moments Claude Code marked
///   (launch it in Dark for the board's last tile).
/// - `st-pick-rec-play`: four moments chosen (0:30), playing.
/// - `st-lb-rec`: the raw recording full size.
/// - `st-pick-rec-only`: only the App Preview, in every language, German
///   shown.
///
/// The recordings are real (`StudioDebugPickRecording`); the first launch
/// makes them, which takes a few seconds.
@MainActor
enum StudioDebugPick {
    nonisolated static let ids = [
        "st-pick-shots-video", "st-pick-alt", "st-lb-pick", "st-pick-duo", "st-pick-rec", "st-pick-rec-play", "st-lb-rec", "st-pick-rec-only",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-pick-shots-video":
            return scene(picking())
        case "st-pick-alt":
            return scene(choseAnother)
        case "st-lb-pick":
            return scene(choseAnother) { model in
                when(model, { $0.studio.run != nil }, then: openTodaysAttempts)
            }
        case "st-pick-duo":
            var run = StudioDebugDuoStates.run(.pick, .both, .sideBySide)
            run.plan.alsoMakes = AutopilotExtras(makesAppPreview: true)
            StudioDebugPickRecording.addRecordings(to: &run)
            return scene(run) { $0.studio.pickDevice = .duo }
        case "st-pick-rec":
            return recordingScene(picking())
        case "st-pick-rec-play":
            var run = picking()
            run.previewMomentIDs = Array(run.plan.screens.prefix(4).map(\.id))
            return recordingScene(run) { model in
                model.studio.recordingPlayer.seek(to: 11)
                model.studio.recordingPlayer.play()
            }
        case "st-lb-rec":
            return recordingScene(picking(), then: openRecording)
        case "st-pick-rec-only":
            var run = StudioDebugRuns.run(.pick)
            AutopilotRunPreset.appPreview.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: false)
            run.plan.alsoMakes.previewLanguages = .all
            StudioDebugPickRecording.addRecordings(to: &run)
            let german = AutopilotRecordingTarget(displayType: .iPhone, locale: "de-DE")
            return recordingScene(run, shown: german) { $0.studio.pickRecording = german }
        default:
            return nil
        }
    }

    /// Pick, with screenshots and an App Preview in English (U.S.).
    static func picking() -> AutopilotRun {
        var run = StudioDebugRuns.run(.pick)
        run.plan.alsoMakes = AutopilotExtras(makesAppPreview: true)
        StudioDebugPickRecording.addRecordings(to: &run)
        return run
    }

    /// Today's attempts full size, at the second.
    private static func openTodaysAttempts(_ model: ScreenshotsViewModel) {
        guard let run = model.studio.run else { return }
        model.studio.openAttempts(run, screenID: run.plan.screens[0].id, at: 1)
    }

    /// The raw recording full size.
    private static func openRecording(_ model: ScreenshotsViewModel) {
        guard let run = model.studio.run else { return }
        model.studio.openRecording(run)
    }

    /// The Week screen's second attempt picked by you.
    private static var choseAnother: AutopilotRun {
        var run = picking()
        let week = run.plan.screens[1].id
        if let second = run.candidates(for: week).first(where: { $0.attempt == 2 }) { run.picks[week] = second.id }
        return run
    }

    private static func scene(_ run: AutopilotRun, setUp: @escaping @MainActor (ScreenshotsViewModel) -> Void = { _ in }) -> StudioDebugExtras.Scene {
        StudioDebugExtras.Scene(run: run, sheet: true, setUp: setUp, savesExtras: false)
    }

    /// The Recording tab, its recording written first; `then` runs once
    /// it's loaded.
    private static func recordingScene(
        _ run: AutopilotRun, shown: AutopilotRecordingTarget? = nil, then: (@MainActor (ScreenshotsViewModel) -> Void)? = nil
    ) -> StudioDebugExtras.Scene {
        let target = shown ?? AutopilotRecordingTarget(displayType: .iPhone, locale: run.plan.primaryLocale)
        return scene(run) { model in
            model.studio.pickTab = .recording
            Task {
                await StudioDebugPickRecording.write([target], run: run, model: model)
                guard let then else { return }
                when(model, { $0.studio.recordingPlayer.canPlay }, then: then)
            }
        }
    }

    /// Runs `action` once `condition` holds (the set and the run load a
    /// moment after the scene opens).
    static func when(
        _ model: ScreenshotsViewModel, _ condition: @escaping @MainActor (ScreenshotsViewModel) -> Bool,
        then action: @escaping @MainActor (ScreenshotsViewModel) -> Void
    ) {
        Task {
            for _ in 0..<200 {
                if condition(model) {
                    action(model)
                    return
                }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}
#endif
