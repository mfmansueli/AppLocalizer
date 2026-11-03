//
//  StudioDebugRunChoice.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 27's scenes, "What this run makes":
/// - `st-plan-reuse`: Screenshots, with the Oct 28 captures reused.
/// - `st-plan-art`: only header and search, from the Oct 28 captures and
///   picks; Capture and Pick are skipped.
/// - `st-plan-video`: only the App Preview on iPhone, in every language.
/// - `st-plan-custom`: iPhone and iPad screenshots and one 16:9 image in
///   English, German, Japanese and Polish.
/// - `st-plan-none`: nothing selected; Start waits.
/// - `st-ready-art`: Ready after an artwork-only run.
@MainActor
enum StudioDebugRunChoice {
    nonisolated static let ids = ["st-plan-reuse", "st-plan-art", "st-plan-video", "st-plan-custom", "st-plan-none", "st-ready-art"]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-plan-reuse":
            StudioDebugExtras.Scene(run: plan { $0.runChoice.reusesCaptures = true }, sheet: true)
        case "st-plan-art":
            StudioDebugExtras.Scene(run: plan { AutopilotRunPreset.headerAndSearch.apply(to: &$0, devices: [.iPhone, .iPad], canReuse: true) }, sheet: true) {
                $0.studio.showsPlanScreens = false
            }
        case "st-plan-video":
            StudioDebugExtras.Scene(run: plan { plan in
                AutopilotRunPreset.appPreview.apply(to: &plan, devices: [.iPhone, .iPad], canReuse: true)
                plan.runChoice.previewDisplays = [.iPhone]
                plan.alsoMakes.previewLanguages = .all
            }, sheet: true)
        case "st-plan-custom":
            StudioDebugExtras.Scene(run: plan { plan in
                plan.setPlans(.iPhoneDuo, false)
                plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: .wide)
                for code in plan.localeCodes { plan.setChooses(code, ["de-DE", "ja"].contains(code)) }
                plan.setChooses("pl", true)
            }, sheet: true) {
                $0.studio.showsPlanScreens = false
            }
        case "st-plan-none":
            StudioDebugExtras.Scene(run: plan { $0.runChoice.makesScreenshots = false }, sheet: true)
        case "st-ready-art":
            StudioDebugExtras.Scene(run: readyArtwork, sheet: true)
        default:
            nil
        }
    }

    /// The plan with the last run's captures and picks kept, then `change`.
    static func plan(_ change: (inout AutopilotPlan) -> Void) -> AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        let kept = StudioDebugRuns.captures(of: StudioDebugRuns.run(.ready).plan, count: .max)
            .map { capture in
                var capture = capture
                capture.receivedAt = StudioDebugRuns.date(day: 28, month: 10, hour: 16)
                return capture
            }
        run.captures = kept
        run.pickBest()
        run.keptCaptureCount = run.keptTargetCount
        run.keptFrom = AutopilotKeptCaptures(
            versionString: "1.3", capturedAt: StudioDebugRuns.date(day: 28, month: 10, hour: 16),
            displayTypes: [.iPhone, .iPad], localeCount: Set(kept.map(\.target.locale)).count, hasPicks: true
        )
        change(&run.plan)
        return run
    }

    /// Ready after only header and search, in Northpier's first direction.
    static var readyArtwork: AutopilotRun {
        var run = StudioDebugExtras.run(.ready)
        AutopilotRunPreset.headerAndSearch.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: true)
        run.templateVersion = nil
        run.shortenings = []
        run.keptFrom = AutopilotKeptCaptures(
            versionString: "1.3", capturedAt: StudioDebugRuns.date(day: 28, month: 10, hour: 16),
            displayTypes: [.iPhone, .iPad], localeCount: run.plan.localeCodes.count, hasPicks: true
        )
        return run
    }
}
#endif
