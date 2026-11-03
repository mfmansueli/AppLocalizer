//
//  StudioDebugDuoStates.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 30's scenes, "iPhone Duo: inner display, cover display or both":
/// - `st-plan-duo-pair`: the plan with both displays side by side (the
///   board's `st-plan-duo`; that name is the Plan's Mac check, board 22).
/// - `st-plan-duo-cover`: the cover display only (launch it in Dark).
/// - `st-plan-duo-sep`: both, as separate screenshots.
/// - `st-cap-duo`: capturing the Duo, opened then folded.
/// - `st-ready-duo`, `st-ready-duo-cover`, `st-ready-duo-both` (Dark),
///   `st-ready-duo-sep`: the new set's iPhone Duo tab in each choice.
/// - `st-lb-duo`: the side-by-side screenshot full size.
@MainActor
enum StudioDebugDuoStates {
    nonisolated static let ids = [
        "st-plan-duo-pair", "st-plan-duo-cover", "st-plan-duo-sep", "st-cap-duo",
        "st-ready-duo", "st-ready-duo-cover", "st-ready-duo-both", "st-ready-duo-sep", "st-lb-duo",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-plan-duo-pair": plan(.both, .sideBySide)
        case "st-plan-duo-cover":
            plan(.cover, .sideBySide) { $0.studio.appearance = .dark }
        case "st-plan-duo-sep": plan(.both, .separate)
        case "st-cap-duo": StudioDebugExtras.Scene(run: capturing, sheet: true, savesExtras: false)
        case "st-ready-duo": ready(.inner, .sideBySide)
        case "st-ready-duo-cover": ready(.cover, .sideBySide)
        case "st-ready-duo-both":
            ready(.both, .sideBySide) { $0.studio.appearance = .dark }
        case "st-ready-duo-sep": ready(.both, .separate)
        case "st-lb-duo":
            ready(.both, .sideBySide) { model in
                StudioDebugPick.when(model) {
                    !$0.studio.preview.shots.isEmpty && $0.studio.preview.displayType == .iPhoneDuo
                } then: {
                    $0.studio.openGallery(at: 0)
                }
            }
        default: nil
        }
    }

    /// A run with iPhone Duo in the plan, its row set to `screens` and
    /// `both`.
    static func run(_ stage: AutopilotStage, _ screens: AutopilotDuoScreens, _ both: AutopilotDuoBoth) -> AutopilotRun {
        var run = StudioDebugRuns.run(stage)
        run.plan.setPlans(.iPhoneDuo, true)
        run.plan.runChoice.duoScreens = screens
        run.plan.runChoice.duoBoth = both
        guard stage != .plan else { return run }
        run.captures = StudioDebugRuns.captures(of: run.plan, count: run.plan.targets.count)
        run.picks = [:]
        run.pickBest()
        return run
    }

    private static func plan(
        _ screens: AutopilotDuoScreens, _ both: AutopilotDuoBoth, setUp: @escaping @MainActor (ScreenshotsViewModel) -> Void = { _ in }
    ) -> StudioDebugExtras.Scene {
        StudioDebugExtras.Scene(run: run(.plan, screens, both), sheet: true, setUp: setUp, savesExtras: false)
    }

    /// Capturing iPhone Duo's first screens, opened then folded, side by
    /// side.
    private static var capturing: AutopilotRun {
        var run = run(.capture, .both, .sideBySide)
        let duo = run.plan.targets.filter { $0.displayType == .iPhoneDuo && $0.locale == run.plan.primaryLocale }
        let last = duo.dropFirst(2).first ?? duo.last
        let count = last.flatMap { run.plan.targets.firstIndex(of: $0) }.map { $0 + 1 } ?? run.plan.targets.count
        run.captures = StudioDebugRuns.captures(of: run.plan, count: count)
        var minute = 9
        for target in duo.prefix(3) {
            guard let pose = run.plan.duoPose(for: target) else { continue }
            let time = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: minute)
            run.appendLog(pose.launchLine(locale: target.locale), kind: .command, at: time)
            let name = run.plan.screen(id: target.screenID)?.name ?? target.screenID
            let slot = (run.plan.slot(of: target.screenID) ?? 0) + 1
            run.appendLog("screenshot → \(target.locale)/iPhone Duo-\(String(format: "%02d", slot)).png · \(name) · attempt 1", kind: .event, at: time)
            minute += 1
        }
        return run
    }

    /// The page on the new set's iPhone Duo tab, its captures placed the
    /// way the row says.
    private static func ready(
        _ screens: AutopilotDuoScreens, _ both: AutopilotDuoBoth, setUp: @escaping @MainActor (ScreenshotsViewModel) -> Void = { _ in }
    ) -> StudioDebugExtras.Scene {
        let shown = run(.ready, screens, both)
        return StudioDebugExtras.Scene(run: shown, sheet: false, setUp: { model in
            model.studio.choice = .new
            model.studio.device = .iPhoneDuo
            setUp(model)
        }, savesExtras: false, documentChange: { document in
            AutopilotLocalizer.place(shown, in: &document)
        })
    }
}
#endif
