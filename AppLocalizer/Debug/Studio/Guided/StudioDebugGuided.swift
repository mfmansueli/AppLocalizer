//
//  StudioDebugGuided.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The Autopilot (board 21), the guided sheet at each step:
/// - `ap-home`: the Screenshots page with no run: the strip's Start….
/// - `ap-plan-mac`: Plan · This Mac with iPhone Duo closed, the iPad
///   simulator to make (Start waits) and the simulator options open.
/// - `ap-plan-helper`: Plan · This Mac with a helper too old to check.
/// - `ap-make`: What to make, screenshots, App Preview and header on.
/// - `ap-make-some`: What to make, only the header and search.
/// - `ap-look`: Look with the design source's own looks.
/// - `ap-look-tpl`, `ap-look-tpl-de`: Look from gallery templates, Cinema
///   and Editorial picked, previewed in English and in German.
/// - `ap-look-art`: Look in a header-only run, three scenes picked.
/// - `ap-look-proof`: Look from one template, Highlight, previewed.
/// - `ap-look-devices`: Arcade previewed in German on iPad, the run making
///   iPhone, iPad, iPhone Duo, Apple Vision Pro and Apple Watch; Lumen's
///   Mac app is captured but not in the run, so Mac carries a +.
/// - `ap-look-mac`: the same, previewed on Mac: on a MacBook, with Add Mac
///   to the Run.
/// - `ap-look-zoom`: Arcade's third screenshot larger in the viewer, in
///   Arabic.
/// - `ap-look-arcade`: Look from Highlight and the new Arcade, Arcade
///   previewed in German.
/// - `ap-plan`: Here's the plan.
/// - `ap-run`: Making it while the assistant captures.
/// - `ap-run-des`: Making it while the looks and headers arrive.
/// - `ap-hidden`: the page's strip while it designs, the sheet closed.
/// - `ap-choose`: Choose, the looks and headers, nothing chosen yet.
/// - `ap-choose-tpl`: Choose from the person's template picks, Arcade,
///   Cinema and Editorial, made in Northpier Brand, Arcade chosen.
/// - `ap-review`: Review & push, the screenshots' tab.
/// - `ap-review-art`: Review & push, the screenshots approved, the header
///   and search's tab.
/// - `ap-review-devices`: Review & push on every device Lumen ships on,
///   Mac shown in Arabic; iPad and Mac were captured in 4 languages
///   before the run.
/// - `ap-done`: Sent to the App Store.
@MainActor
enum StudioDebugGuided {
    nonisolated static let homeID = "ap-home"

    nonisolated static let ids = [
        homeID, "ap-make", "ap-make-some", "ap-look", "ap-look-tpl", "ap-look-tpl-de", "ap-look-art", "ap-look-proof",
        "ap-look-devices", "ap-look-mac", "ap-look-zoom", "ap-look-arcade", "ap-plan", "ap-plan-mac", "ap-plan-helper",
        "ap-run", "ap-run-des", "ap-hidden", "ap-choose", "ap-choose-tpl", "ap-review", "ap-review-art", "ap-review-devices", "ap-done",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        setupScene(for: id) ?? lookScene(for: id) ?? deviceScene(for: id) ?? runScene(for: id)
    }

    private static func setupScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "ap-make":
            guided(planned(), step: .make)
        case "ap-make-some":
            guided(planned(screenshots: false, appPreview: false), step: .make)
        case "ap-plan":
            guided(planned(), step: .plan)
        case "ap-plan-mac":
            // iPhone, iPad and iPhone Duo: the iPad simulator to make, the
            // Duo closed, the simulator options open.
            planMac()
        case "ap-plan-helper":
            planHelper()
        default:
            nil
        }
    }

    /// Look: the template cards, the gallery's picks and the artwork.
    private static func lookScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "ap-look":
            guided(planned(), step: .look)
        case "ap-look-tpl":
            guided(templates([.cinema, .editorial]), step: .look)
        case "ap-look-tpl-de":
            guided(templates([.cinema, .editorial]), step: .look) { $0.templateLocale = "de-DE" }
        case "ap-look-art":
            guided(planned(screenshots: false, appPreview: false), step: .look)
        case "ap-look-proof":
            guided(templates([.highlight]), step: .look) { $0.templateFocus = .highlight }
        case "ap-look-arcade":
            guided(templates([.highlight, .arcade]), step: .look) { guided in
                guided.templateFocus = .arcade
                guided.templateLocale = "de-DE"
            }
        default:
            nil
        }
    }

    private static func planMac() -> StudioDebugExtras.Scene {
        DebugSimulators.runWithoutIPad()
        var run = planned()
        run.plan.setPlans(.iPhoneDuo, true)
        return guided(run, step: .plan) { $0.showsSimulator = true }
    }

    private static func planHelper() -> StudioDebugExtras.Scene {
        DebugSimulators.runOldHelper()
        return guided(planned(), step: .plan)
    }

    /// Look on Lumen's every device: iPad, Mac and the larger viewer.
    private static func deviceScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "ap-look-devices":
            guided(templates([.arcade], everyDevice: true), step: .look, everyDevice: true, withMac: true) { guided in
                guided.templateFocus = .arcade
                guided.templateLocale = "de-DE"
                guided.templateDevice = .iPad
            }
        case "ap-look-mac":
            guided(templates([.arcade], everyDevice: true), step: .look, everyDevice: true, withMac: true) { guided in
                guided.templateFocus = .arcade
                guided.templateLocale = "de-DE"
                guided.templateDevice = .mac
            }
        case "ap-look-zoom":
            guided(templates([.arcade], everyDevice: true), step: .look, everyDevice: true, setUp: { guided in
                guided.templateFocus = .arcade
                guided.templateLocale = "ar-SA"
            }, then: { model in
                guard let plan = model.studio.run?.plan else { return false }
                model.studio.openTemplatePreview(.arcade, plan: plan, at: 2)
                return model.studio.viewer != nil
            })
        default:
            nil
        }
    }

    private static func runScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "ap-run":
            guided(started(StudioDebugExtras.run(.capture, languages: .primary)), savesExtras: false)
        case "ap-run-des":
            guided(designing(arrived: 2), savesExtras: false)
        case "ap-hidden":
            guided(designing(arrived: 1), sheet: false, savesExtras: false)
        case "ap-choose":
            guided(choosing, savesExtras: false)
        case "ap-choose-tpl":
            guided(choosingTemplates, savesExtras: false)
        case "ap-review":
            guided(ready(approved: []), setUp: { $0.reviewPart = .screenshots })
        case "ap-review-art":
            guided(ready(approved: [.screenshots]), setUp: { $0.reviewPart = .artwork })
        case "ap-review-devices":
            reviewEveryDevice()
        case "ap-done":
            guided(ready(approved: GuidedReviewPart.allCases, pushed: true))
        default:
            nil
        }
    }

    // MARK: - Runs

    /// A new guided plan making the three parts asked, header and search
    /// from three scene templates; on every device Lumen runs on (iPhone
    /// Duo, Apple Vision Pro and Apple Watch too) when `everyDevice`.
    static func planned(screenshots: Bool = true, appPreview: Bool = true, artwork: Bool = true, everyDevice: Bool = false) -> AutopilotRun {
        var run = StudioDebugExtras.run(.plan, languages: .primary, everyDevice: everyDevice)
        if everyDevice { run.plan.setPlans(.iPhoneDuo, true) }
        GuidedDefaults.apply(to: &run.plan)
        run.plan.alsoMakes.headerTemplates = [.night, .land, .window]
        let devices = run.plan.displayTypes
        GuidedDefaults.setMakes(.screenshots, screenshots, in: &run.plan, devices: devices, canReuse: true)
        GuidedDefaults.setMakes(.appPreview, appPreview, in: &run.plan, devices: devices, canReuse: true)
        GuidedDefaults.setMakes(.artwork, artwork, in: &run.plan, devices: devices, canReuse: true)
        return run
    }

    /// The plan with screenshots from `starters`.
    static func templates(_ starters: [TemplateStarter], everyDevice: Bool = false) -> AutopilotRun {
        var run = planned(everyDevice: everyDevice)
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

    /// Choose from three template picks: one look per pick, each its
    /// template as the gallery has it, Arcade (the first) chosen.
    static var choosingTemplates: AutopilotRun {
        var run = started(StudioDebugExtras.run(.choose, languages: .primary))
        let picks: [TemplateStarter] = [.arcade, .cinema, .editorial]
        let rationales: [TemplateStarter: String] = [
            .arcade: "Loud and playful: Lumen’s prompts as a game you return to.",
            .cinema: "Dark and calm, for writing at night.",
            .editorial: "Quiet type and lavender, like a paper journal.",
        ]
        run.plan.screenshotStyle = .templates
        run.plan.screenshotTemplates = picks.map(\.title)
        run.directions = picks.map { starter in
            AutopilotDirection(
                id: "tpl-\(starter.rawValue)", name: AutopilotShotStyle.directionName(template: starter.title, app: "Lumen"),
                rationale: rationales[starter] ?? "", source: .claudeDesign,
                template: ScreenshotTemplate.starter(starter, id: StudioDebugRuns.appID, title: "Lumen Journal", slotCount: run.plan.screens.count),
                receivedAt: StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 12)
            )
        }
        run.directionPick = run.directions.first?.id
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

    /// Review & push on iPhone, iPad, iPhone Duo, Mac, Apple Vision Pro and
    /// Apple Watch, on Mac in Arabic: the run captured Mac in every
    /// language, where it had 4 before, like iPad.
    private static func reviewEveryDevice() -> StudioDebugExtras.Scene {
        var run = started(StudioDebugExtras.run(.ready, languages: .primary, everyDevice: true))
        run.plan.setPlans(.mac, true)
        run.plan.setPlans(.iPhoneDuo, true)
        run.captures = StudioDebugRuns.captures(of: run.plan, count: run.plan.targets.count)
        run.pickBest()
        run.guidedReview = AutopilotGuidedReview()
        var before = ScreenshotsDebugDocuments.document(for: .standard)
        DebugEveryDevice.addMac(to: &before)
        run.interfaceGaps = AutopilotInterfaceGap.gaps(in: run.plan, captures: before.captures)
        let locales = run.plan.localeCodes
        var scene = guided(run, everyDevice: true) { guided in
            guided.reviewPart = .screenshots
            guided.reviewDevice = .mac
            guided.reviewLocale = "ar-SA"
        }
        scene.documentChange = { DebugEveryDevice.addMac(to: &$0, locales: locales) }
        return scene
    }

    // MARK: - Scenes

    private static func guided(
        _ run: AutopilotRun,
        step: GuidedStep? = nil,
        sheet: Bool = true,
        savesExtras: Bool = true,
        everyDevice: Bool = false,
        withMac: Bool = false,
        setUp: (@MainActor (GuidedSheetModel) -> Void)? = nil,
        then action: (@MainActor (ScreenshotsViewModel) -> Bool)? = nil
    ) -> StudioDebugExtras.Scene {
        var scene = StudioDebugExtras.Scene(run: run, sheet: sheet, setUp: { model in
            if let step { model.studio.guided.setupStep = step }
            setUp?(model.studio.guided)
            if let action { retry(action, on: model) }
        }, savesExtras: savesExtras, everyDevice: everyDevice)
        if withMac { scene.documentChange = DebugEveryDevice.addMac(to:) }
        return scene
    }

    /// Does `action` once the set is read and it can: it says whether it
    /// did.
    private static func retry(_ action: @escaping @MainActor (ScreenshotsViewModel) -> Bool, on model: ScreenshotsViewModel) {
        Task {
            for _ in 0..<200 {
                if model.document != nil, action(model) { return }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
}
#endif
