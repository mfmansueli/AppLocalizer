//
//  StudioDebugPreviewReview.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 29's scenes, "App Preview review, music and full-size viewer":
/// - `st-plan-music`: the plan making an App Preview, with its Music row.
/// - `st-vid`: Watch the App Preview, v1, English (U.S.) only.
/// - `st-vid-mid`: the same at 0:08, paused.
/// - `st-vid-de`: every language has its own, German shown at 0:13 (launch
///   it in Dark).
/// - `st-vid-busy`: Claude Design revising “Slower pace, start with Search”.
/// - `st-vid-rev`: v2 from Claude Design, slower and starting with Search,
///   at 0:02.
/// - `st-lb-shot`, `st-lb-header` (launch it in Dark), `st-lb-video`: the
///   new set's second screenshot, header and App Preview full size.
/// - `st-lb-dir`: Choose a direction with the second direction's first
///   screenshot full size.
///
/// The App Previews are real (`StudioDebugPreviewMovies`); the first
/// launch makes them, which takes a few seconds.
@MainActor
enum StudioDebugPreviewReview {
    nonisolated static let ids = [
        "st-plan-music", "st-vid", "st-vid-mid", "st-vid-de", "st-vid-busy", "st-vid-rev",
        "st-lb-shot", "st-lb-header", "st-lb-video", "st-lb-dir",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-plan-music":
            var run = StudioDebugExtras.run(.plan, languages: .primary)
            run.plan.alsoMakes.makesArtwork = false
            // iPhone and iPad, like the board: the Music row shows without scrolling.
            run.plan.setPlans(.iPhoneDuo, false)
            return StudioDebugExtras.Scene(run: run, sheet: true) { $0.studio.showsPlanScreens = false }
        case "st-vid", "st-vid-mid", "st-vid-de", "st-vid-busy", "st-vid-rev":
            return watchScene(id)
        default:
            return viewerScene(id)
        }
    }

    /// Watch the App Preview, iPhone and iPad.
    private static func watchScene(_ id: String) -> StudioDebugExtras.Scene {
        var run = watching(languages: id == "st-vid-de" ? .all : .primary)
        let asked = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 31)
        switch id {
        case "st-vid-busy":
            run.previewReview?.request = AutopilotRevisionRequest(note: "Slower pace, start with Search", askedAt: asked)
            run.handedBackAt = asked
            run.appendLog("Asked Claude Design for App Preview changes: “Slower pace, start with Search”", kind: .command, at: asked)
        case "st-vid-rev":
            let ids = run.plan.screens.map(\.id)
            let search = ids.first { $0.contains("search") } ?? ids[0]
            run.previewReview?.cut = AppPreviewCut(screenIDs: [search] + ids.filter { $0 != search }, seconds: 28)
            run.previewReview?.version = 2
            run.previewReview?.revisions = [AutopilotPreviewRevision(
                version: 2, changes: "Slower pace, starts with Search", note: "Slower pace, start with Search", client: "Claude Code",
                madeAt: asked
            )]
        default:
            break
        }
        let seconds: Double? = switch id {
        case "st-vid-mid": 8
        case "st-vid-de": 13
        case "st-vid-rev": 2
        default: nil
        }
        let shown = run
        let targets: [(ScreenshotDisplayType, String)] = id == "st-vid-de"
            ? [(.iPhone, "de-DE"), (.iPhone, "en-US")]
            : shown.plan.previewDisplays.map { ($0, shown.plan.primaryLocale) }
        return StudioDebugExtras.Scene(run: run, sheet: true) { model in
            if id == "st-vid-de" { model.studio.watchedLocale = "de-DE" }
            Task { await StudioDebugPreviewMovies.make(targets, run: shown, model: model, seconds: seconds) }
        }
    }

    /// The full-size viewer over the new set's preview, or over Choose a
    /// direction.
    private static func viewerScene(_ id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-lb-shot":
            return StudioDebugExtras.Scene(run: StudioDebugRuns.run(.ready), sheet: false, setUp: { model in
                model.studio.choice = .new
                open(model, when: { !$0.studio.preview.shots.isEmpty }, then: { $0.studio.openGallery(at: 1) })
            }, savesExtras: false)
        case "st-lb-header":
            return StudioDebugExtras.Scene(run: StudioDebugExtras.run(.ready, languages: .primary), sheet: false) { model in
                model.studio.choice = .new
                open(model, when: { $0.studio.extrasPreview?.header != nil }, then: { $0.studio.openArtwork(at: 0) })
            }
        case "st-lb-video":
            let run = StudioDebugExtras.run(.ready, languages: .primary)
            return StudioDebugExtras.Scene(run: run, sheet: false) { model in
                model.studio.choice = .new
                open(model, when: { $0.studio.extrasPreview?.appPreview != nil }, then: { $0.studio.openGallery(at: 0) })
                Task { await StudioDebugPreviewMovies.make([(.iPhone, run.plan.primaryLocale)], run: run, model: model, seconds: 7) }
            }
        case "st-lb-dir":
            return StudioDebugExtras.Scene(run: StudioDebugRuns.run(.choose), sheet: true, setUp: { model in
                open(model, when: { ($0.studio.run?.directions.count ?? 0) > 1 }, then: { model in
                    guard let direction = model.studio.run?.directions[1] else { return }
                    model.studio.openDirection(direction, at: 0)
                })
            }, savesExtras: false)
        default:
            return nil
        }
    }

    /// The run at Watch the App Preview, v1, making only the App Preview.
    private static func watching(languages: AutopilotPreviewLanguages) -> AutopilotRun {
        var run = StudioDebugExtras.run(.watchPreview, languages: languages)
        run.plan.alsoMakes.makesArtwork = false
        run.previewReview = AutopilotPreviewReview()
        run.appendLog("App Preview v1 ready to watch", kind: .event, at: StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 30))
        return run
    }

    /// Runs `action` once `condition` holds (the set and the run load a
    /// moment after the scene opens).
    private static func open(
        _ model: ScreenshotsViewModel, when condition: @escaping @MainActor (ScreenshotsViewModel) -> Bool,
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
