//
//  StudioDebugHeaderStyle.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Header concepts, chosen apart from the screenshot direction:
/// - `st-plan-tpl`, `st-plan-free`: the plan's Header style, three scene
///   templates picked, or Go freely with the person's words.
/// - `st-plan-shotstyle`: Screenshot style, two gallery templates picked.
/// - `st-des-tpl`, `st-des-free`: Design while the concepts arrive: one
///   designed and one an idea yet, or only the first idea.
/// - `st-choose-tpl`: Choose a direction and a header, the second
///   direction and the first header chosen.
/// - `st-choose-free`: Choose a header, Claude Design's own, still images.
/// - `st-lb-concept`: a concept's header and search full size.
/// - `st-vid-loop`, `st-vid-loop-rev`: Watch the header loop, v1, and v2
///   after the person asked for slower movement.
@MainActor
enum StudioDebugHeaderStyle {
    nonisolated static let ids = [
        "st-plan-tpl", "st-plan-free", "st-plan-shotstyle", "st-des-tpl", "st-des-free", "st-choose-tpl", "st-choose-free",
        "st-lb-concept", "st-vid-loop", "st-vid-loop-rev",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        planScene(for: id) ?? chooseScene(for: id)
    }

    private static func planScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-plan-tpl":
            StudioDebugExtras.Scene(run: headerOnly(.plan), sheet: true) { $0.studio.showsPlanScreens = false }
        case "st-plan-free":
            StudioDebugExtras.Scene(run: headerOnly(.plan, style: .free), sheet: true) { $0.studio.showsPlanScreens = false }
        case "st-plan-shotstyle":
            StudioDebugExtras.Scene(run: shotStyle, sheet: true) { $0.studio.showsPlanScreens = false }
        case "st-des-tpl":
            StudioDebugExtras.Scene(run: designing(headerOnly(.design), arrived: 2, designed: 1), sheet: true, savesExtras: false)
        case "st-des-free":
            StudioDebugExtras.Scene(run: designing(headerOnly(.design, style: .free), arrived: 1, designed: 0), sheet: true, savesExtras: false)
        default:
            nil
        }
    }

    private static func chooseScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-choose-tpl":
            StudioDebugExtras.Scene(run: choosingBoth, sheet: true, savesExtras: false)
        case "st-choose-free":
            StudioDebugExtras.Scene(run: headerOnly(.choose, style: .free, motion: .still), sheet: true, savesExtras: false)
        case "st-lb-concept":
            StudioDebugExtras.Scene(run: headerOnly(.choose), sheet: true, setUp: { model in
                StudioDebugPick.when(model) { $0.studio.run?.stage == .choose } then: { model in
                    guard let concept = model.studio.run?.conceptList.dropFirst().first else { return }
                    model.studio.openConcept(concept, at: 0)
                }
            }, savesExtras: false)
        case "st-vid-loop":
            StudioDebugExtras.Scene(run: watching(version: 1), sheet: true, savesExtras: false)
        case "st-vid-loop-rev":
            StudioDebugExtras.Scene(run: watching(version: 2), sheet: true, savesExtras: false)
        default:
            nil
        }
    }

    /// Only the header and search (the live screenshots stay), a 20-second
    /// loop from the picked templates or Claude Design's own concepts.
    static func headerOnly(
        _ stage: AutopilotStage, style: AutopilotArtworkStyle = .templates, motion: AutopilotArtworkMotion = .loop
    ) -> AutopilotRun {
        var run = StudioDebugExtras.run(stage == .plan ? .plan : .choose, languages: .primary)
        AutopilotRunPreset.headerAndSearch.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: true)
        run.plan.alsoMakes.setMotion(motion)
        run.plan.alsoMakes.artworkStyle = style
        run.plan.alsoMakes.headerTemplates = style == .templates ? [.night, .land, .window] : []
        if style == .free { run.plan.alsoMakes.artworkDirection.text = "Calm, like writing before bed" }
        guard stage != .plan else { return run }
        run.stage = stage
        run.proposesConcepts = true
        run.directions = []
        run.concepts = style == .templates ? StudioDebugConcepts.fromTemplates : StudioDebugConcepts.free
        return run
    }

    /// Screenshots from two gallery templates, no header or search.
    static var shotStyle: AutopilotRun {
        var run = StudioDebugRuns.run(.plan)
        run.plan.alsoMakes = AutopilotExtras()
        run.plan.screenshotStyle = .templates
        run.plan.screenshotTemplates = [TemplateStarter.cinema.title, TemplateStarter.editorial.title]
        return run
    }

    /// Design with the first `arrived` concepts come so far, the first
    /// `designed` of them with pages.
    static func designing(_ run: AutopilotRun, arrived: Int, designed: Int) -> AutopilotRun {
        var run = run
        run.concepts = run.conceptList.prefix(arrived).enumerated().map { index, concept in
            var concept = concept
            if index >= designed { concept.design = nil }
            return concept
        }
        run.briefReadAt = StudioDebugRuns.date(day: 4, month: 11, hour: 14, minute: 2)
        return run
    }

    /// Screenshots and the header: three directions and three concepts,
    /// the second direction and the first header chosen.
    static var choosingBoth: AutopilotRun {
        var run = StudioDebugExtras.run(.choose, languages: .primary)
        run.plan.alsoMakes.makesAppPreview = false
        run.plan.alsoMakes.setMotion(.loop)
        run.plan.alsoMakes.headerTemplates = [.night, .land, .window]
        run.proposesConcepts = true
        for index in run.directions.indices { run.directions[index].artworkDesign = nil }
        run.concepts = StudioDebugConcepts.fromTemplates
        run.directionPick = run.directions.dropFirst().first?.id
        run.art = "A"
        return run
    }

    /// Watch the header loop at `version`: Moonrise animated at v1,
    /// Evening Hills at v2 after the person's note, with the night sky's
    /// pages, which move.
    static func watching(version: Int) -> AutopilotRun {
        var run = headerOnly(.choose)
        run.stage = .watchPreview
        run.art = version > 1 ? "B" : "A"
        let index = run.conceptList.firstIndex { $0.id == run.art } ?? 0
        run.concepts?[index].motion = StudioDebugWebArtwork.quietIndigo
        for code in run.plan.localeCodes { run.localeStatus[code] = .fits(note: nil) }
        var review = AutopilotLoopReview(conceptID: run.art ?? "A")
        review.version = version
        if version > 1 {
            review.revisions = [AutopilotLoopRevision(
                version: 2, changes: "Slower movement, warmer light", note: "Slower movement, warmer light", client: "Claude Code",
                madeAt: StudioDebugRuns.date(day: 4, month: 11, hour: 15, minute: 12)
            )]
        }
        run.loopReview = review
        return run
    }
}
#endif
