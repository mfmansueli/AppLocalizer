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
/// - `st-des-header-loop`: Design in a Header 21:9 only run with Motion
///   loop: the first concept's loop is in, the other two are animating.
/// - `st-choose-header-loop`: Choose a header in that run, each concept
///   playing its loop.
/// - `st-lb-concept`: a concept's header and search full size.
/// - `st-vid-loop`, `st-vid-loop-rev`: Watch the header loop, v1, and v2
///   after the person asked for slower movement.
/// - `st-vid-loop-making`: the loop's new version being made, half its
///   languages done.
/// - `st-ready-header-failed`: Ready for review in that run, its header
///   not made (the page didn't load), with Make Again.
@MainActor
enum StudioDebugHeaderStyle {
    nonisolated static let ids = [
        "st-plan-tpl", "st-plan-free", "st-plan-shotstyle", "st-des-tpl", "st-des-free", "st-choose-tpl", "st-choose-free",
        "st-des-header-loop", "st-choose-header-loop", "st-lb-concept", "st-vid-loop", "st-vid-loop-rev", "st-vid-loop-making",
        "st-ready-header-failed",
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
        case "st-choose-header-loop":
            StudioDebugExtras.Scene(run: headerLoopOnly, sheet: true, savesExtras: false)
        case "st-des-header-loop":
            StudioDebugExtras.Scene(run: animatingLoops, sheet: true, savesExtras: false)
        case "st-lb-concept":
            StudioDebugExtras.Scene(run: headerOnly(.choose), sheet: true, setUp: { model in
                StudioDebugPick.when(model) { $0.studio.run?.stage == .choose } then: { model in
                    guard let concept = model.studio.run?.conceptList.dropFirst().first else { return }
                    model.studio.openConcept(concept, at: 0)
                }
            }, savesExtras: false)
        default:
            watchScene(for: id)
        }
    }

    private static func watchScene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-vid-loop":
            StudioDebugExtras.Scene(run: watching(version: 1), sheet: true, savesExtras: false)
        case "st-vid-loop-rev":
            StudioDebugExtras.Scene(run: watching(version: 2), sheet: true, savesExtras: false)
        case "st-vid-loop-making":
            StudioDebugExtras.Scene(run: makingLoopAgain, sheet: true, savesExtras: false)
        case "st-ready-header-failed":
            StudioDebugExtras.Scene(run: headerNotMade, sheet: true, savesExtras: false)
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

    /// Choose in a run that makes only the 21:9 header, as a loop, from
    /// Claude Design's own concepts, each animated at Design.
    static var headerLoopOnly: AutopilotRun {
        var run = headerOnly(.choose, style: .free)
        run.plan.alsoMakes.setArtworkSize(.headerOnly)
        run.animatesConcepts = true
        for index in run.conceptList.indices { run.concepts?[index].motion = StudioDebugWebArtwork.quietIndigo }
        return run
    }

    /// `headerLoopOnly` back at Design: the first concept's loop is in, the
    /// other two have their stills and are being animated.
    static var animatingLoops: AutopilotRun {
        var run = headerLoopOnly
        run.stage = .design
        for index in run.conceptList.indices.dropFirst() { run.concepts?[index].motion = nil }
        run.briefReadAt = StudioDebugRuns.date(day: 4, month: 11, hour: 14, minute: 2)
        return run
    }

    /// `headerLoopOnly` at Ready for review, B chosen, its header not made:
    /// the page didn't load.
    static var headerNotMade: AutopilotRun {
        var run = headerLoopOnly
        run.stage = .ready
        run.art = "B"
        run.loopReview = AutopilotLoopReview(conceptID: "B")
        for code in run.plan.localeCodes { run.localeStatus[code] = .fits(note: nil) }
        var progress = AutopilotExtrasProgress()
        progress.artworkTotal = run.plan.localeCodes.count
        progress.artworkDone = progress.artworkTotal
        progress.artworkProblem = "Couldn’t render the header page in English (U.S.): The page didn’t load"
        progress.isFinished = true
        run.extrasProgress = progress
        run.finishedAt = StudioDebugRuns.date(day: 4, month: 11, hour: 21, minute: 40)
        run.appendLog(AutopilotCenter.readyLine(for: run), kind: .problem, at: run.finishedAt ?? .now)
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

    /// Watch the header loop with its new version arrived and half its
    /// languages made, at 4 minutes each.
    static var makingLoopAgain: AutopilotRun {
        var run = watching(version: 1)
        run.loopReview?.request = AutopilotRevisionRequest(note: "Slower movement", askedAt: .now)
        run.loopReview?.isRemaking = true
        var progress = AutopilotExtrasProgress()
        progress.artworkTotal = run.plan.localeCodes.count
        progress.artworkDone = max(1, progress.artworkTotal / 2)
        progress.artworkDoneAt = .now.addingTimeInterval(-60)
        progress.artworkStartedAt = .now.addingTimeInterval(-60 - Double(progress.artworkDone) * 240)
        run.extrasProgress = progress
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
