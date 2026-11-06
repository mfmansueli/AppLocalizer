//
//  StudioDebugGuided.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Autopilot v2 (board StudioV2), the guided sheet at each step:
/// - `v2-home`: the Screenshots page with no run: the strip's Start….
/// - `v2-make`: What to make, screenshots, App Preview and header on.
/// - `v2-make-some`: What to make, only the header and search.
/// - `v2-look`: Look with the design source's own looks.
/// - `v2-look-tpl`, `v2-look-tpl-de`: Look from gallery templates, Cinema
///   and Editorial picked, previewed in English and in German.
/// - `v2-look-art`: Look in a header-only run, three scenes picked.
/// - `v2-look-proof`: Look from one template, Highlight, previewed.
/// - `v2-plan`: Here's the plan.
/// - `v2-run`: Making it while the assistant captures.
/// - `v2-run-des`: Making it while the looks and headers arrive.
/// - `v2-hidden`: the page's strip while it designs, the sheet closed.
/// - `v2-choose`: Choose, the looks and headers, nothing chosen yet.
/// - `v2-review`: Review & push, the screenshots' tab.
/// - `v2-review-art`: Review & push, the screenshots approved, the header
///   and search's tab.
/// - `v2-done`: Sent to the App Store.
@MainActor
enum StudioDebugGuided {
    nonisolated static let homeID = "v2-home"

    nonisolated static let ids = [
        homeID, "v2-make", "v2-make-some", "v2-look", "v2-look-tpl", "v2-look-tpl-de", "v2-look-art", "v2-look-proof", "v2-plan",
        "v2-run", "v2-run-des", "v2-hidden", "v2-choose", "v2-review", "v2-review-art", "v2-done",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        setupScene(for: id) ?? runScene(for: id)
    }

    private static func setupScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "v2-make":
            guided(planned(), step: .make)
        case "v2-make-some":
            guided(planned(screenshots: false, appPreview: false), step: .make)
        case "v2-look":
            guided(planned(), step: .look)
        case "v2-look-tpl":
            guided(templates([.cinema, .editorial]), step: .look)
        case "v2-look-tpl-de":
            guided(templates([.cinema, .editorial]), step: .look) { $0.templateLocale = "de-DE" }
        case "v2-look-art":
            guided(planned(screenshots: false, appPreview: false), step: .look)
        case "v2-look-proof":
            guided(templates([.highlight]), step: .look) { $0.templateFocus = .highlight }
        case "v2-plan":
            guided(planned(), step: .plan)
        default:
            nil
        }
    }

    private static func runScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "v2-run":
            guided(started(StudioDebugExtras.run(.capture, languages: .primary)), savesExtras: false)
        case "v2-run-des":
            guided(designing(arrived: 2), savesExtras: false)
        case "v2-hidden":
            guided(designing(arrived: 1), sheet: false, savesExtras: false)
        case "v2-choose":
            guided(choosing, savesExtras: false)
        case "v2-review":
            guided(ready(approved: []), setUp: { $0.reviewPart = .screenshots })
        case "v2-review-art":
            guided(ready(approved: [.screenshots]), setUp: { $0.reviewPart = .artwork })
        case "v2-done":
            guided(ready(approved: GuidedReviewPart.allCases, pushed: true))
        default:
            nil
        }
    }

    // MARK: - Runs

    /// A new guided plan making the three parts asked, header and search
    /// from three scene templates.
    static func planned(screenshots: Bool = true, appPreview: Bool = true, artwork: Bool = true) -> AutopilotRun {
        var run = StudioDebugExtras.run(.plan, languages: .primary)
        GuidedDefaults.apply(to: &run.plan)
        run.plan.alsoMakes.headerTemplates = [.night, .land, .window]
        let devices = run.plan.displayTypes
        GuidedDefaults.setMakes(.screenshots, screenshots, in: &run.plan, devices: devices, canReuse: true)
        GuidedDefaults.setMakes(.appPreview, appPreview, in: &run.plan, devices: devices, canReuse: true)
        GuidedDefaults.setMakes(.artwork, artwork, in: &run.plan, devices: devices, canReuse: true)
        return run
    }

    /// The plan with screenshots from `starters`.
    static func templates(_ starters: [TemplateStarter]) -> AutopilotRun {
        var run = planned()
        run.plan.screenshotStyle = .templates
        run.plan.screenshotTemplates = starters.map(\.title)
        return run
    }

    /// `run` with the guided stops.
    static func started(_ run: AutopilotRun) -> AutopilotRun {
        var run = run
        GuidedDefaults.apply(to: &run.plan)
        return run
    }

    /// Screenshots and the header at Choose, nothing chosen yet.
    static var choosing: AutopilotRun {
        var run = started(StudioDebugHeaderStyle.choosingBoth)
        run.directionPick = nil
        run.art = nil
        return run
    }

    /// `choosing` back at Design, the first `arrived` looks and headers in
    /// (the last of them still being designed).
    static func designing(arrived: Int) -> AutopilotRun {
        var run = choosing
        run.stage = .design
        run.directions = Array(run.directions.prefix(arrived))
        return StudioDebugHeaderStyle.designing(run, arrived: arrived, designed: max(arrived - 1, 0))
    }

    /// Ready to review, `approved` approved; pushed a minute ago when
    /// `pushed`.
    static func ready(approved: [GuidedReviewPart], pushed: Bool = false) -> AutopilotRun {
        var run = started(StudioDebugExtras.run(.ready, languages: .primary))
        var review = AutopilotGuidedReview()
        review.approved = approved
        if pushed { review.pushedAt = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 31) }
        run.guidedReview = review
        return run
    }

    // MARK: - Scenes

    private static func guided(
        _ run: AutopilotRun,
        step: GuidedStep? = nil,
        sheet: Bool = true,
        savesExtras: Bool = true,
        setUp: (@MainActor (GuidedSheetModel) -> Void)? = nil
    ) -> StudioDebugExtras.Scene {
        var scene = StudioDebugExtras.Scene(run: run, sheet: sheet, setUp: { model in
            if let step { model.studio.guided.setupStep = step }
            setUp?(model.studio.guided)
        }, savesExtras: savesExtras)
        scene.front = .guided
        return scene
    }
}
#endif
