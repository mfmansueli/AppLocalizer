//
//  StudioDebugArtMotion.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 32's scenes, "Header and search: still or motion":
/// - `st-plan-motion`: only header and search, as a motion loop, from the
///   Oct 28 captures.
/// - `st-des-motion`: Design, with the brief AppLocalizer sends.
/// - `st-ready-motion`: the new set's moving header (launch it in Dark).
/// - `st-lb-header-guide`: the header full size with Show iPhone Area on.
/// - `st-lb-search-motion`: the search image full size, German.
/// - `st-plan-art-custom`: no app, a scene, with the expected result
///   (words and two references) open.
/// - `st-des-art-custom`: Design, the brief with that direction.
/// - `st-lb-search-ui`: the search image with the app and no device.
/// - `st-lb-search-scene`: the search image with no app, a scene,
///   Japanese.
/// - `st-des-revise-motion`: Design while Claude Code makes the person's
///   changes to the three directions, on every device, with header and
///   search loops and the App Preview: the cards fit the sheet and open
///   full size.
/// (`st-ready-extras-wide`, the board's 16:9 tile, is board 26's.)
@MainActor
enum StudioDebugArtMotion {
    nonisolated static let ids = [
        "st-plan-motion", "st-des-motion", "st-ready-motion", "st-lb-header-guide", "st-lb-search-motion",
        "st-plan-art-custom", "st-des-art-custom", "st-lb-search-ui", "st-lb-search-scene", "st-des-revise-motion",
    ]

    /// The board's expected result.
    static let direction = AutopilotArtworkDirection(
        text: "A calm night sky over hills, the moon rising behind the name, Bigger headline",
        references: [
            AutopilotArtworkReference(fileID: "debug-reference-search.mp4", name: "video-search-results-dark.mp4"),
            AutopilotArtworkReference(fileID: "debug-reference-header.mp4", name: "video-product-page-header-dark.mp4"),
        ]
    )

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-plan-motion":
            StudioDebugExtras.Scene(run: artworkOnly(.plan), sheet: true, setUp: { $0.studio.showsPlanScreens = false }, savesExtras: false)
        case "st-des-motion":
            StudioDebugExtras.Scene(run: artworkOnly(.design), sheet: true, savesExtras: false)
        case "st-plan-art-custom":
            StudioDebugExtras.Scene(run: artworkOnly(.plan, shows: .scene, withDirection: true), sheet: true, setUp: { model in
                model.studio.showsPlanScreens = false
                model.studio.showsArtworkDirection = true
            }, savesExtras: false)
        case "st-des-art-custom":
            StudioDebugExtras.Scene(run: artworkOnly(.design, shows: .scene, withDirection: true), sheet: true, savesExtras: false)
        case "st-ready-motion":
            StudioDebugExtras.Scene(run: ready(), sheet: false) { model in
                model.studio.choice = .new
                model.studio.appearance = .dark
            }
        case "st-lb-header-guide":
            viewer(ready(), at: 0) { $0.studio.viewerShowsGuide = true }
        case "st-lb-search-motion":
            viewer(ready(), at: 1, locale: "de-DE")
        case "st-lb-search-ui":
            viewer(ready(shows: .ui, motion: .still), at: 1)
        case "st-lb-search-scene":
            viewer(ready(shows: .scene), at: 1, locale: "ja")
        default:
            id == "st-des-revise-motion" ? StudioDebugExtras.Scene(run: revising, sheet: true, savesExtras: false, everyDevice: true) : nil
        }
    }

    /// The three directions back at Design with the person's note, the
    /// header and search as loops beside an App Preview.
    static var revising: AutopilotRun {
        var run = StudioDebugExtras.run(.choose, languages: .primary, everyDevice: true)
        run.plan.alsoMakes.setMotion(.loop)
        run.stage = .design
        run.revision = AutopilotRevisionRequest(
            note: "Make the header and search images warmer, with the icon bigger", askedAt: StudioDebugRuns.date(day: 31, month: 10, hour: 15, minute: 2)
        )
        return run
    }

    /// Only header and search, as a 20-second loop, from the kept captures
    /// (the plan) or at `stage`.
    static func artworkOnly(_ stage: AutopilotStage, shows: AutopilotArtworkShow = .phone, withDirection: Bool = false) -> AutopilotRun {
        var run = stage == .plan ? StudioDebugRunChoice.plan { _ in } : StudioDebugExtras.run(stage, languages: .primary)
        AutopilotRunPreset.headerAndSearch.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: true)
        run.plan.alsoMakes.setMotion(.loop)
        run.plan.alsoMakes.artworkShows = shows
        if withDirection { run.plan.alsoMakes.artworkDirection = direction }
        return run
    }

    /// Ready, with header and search (a loop unless `motion` says still)
    /// and the App Preview in English (U.S.).
    static func ready(shows: AutopilotArtworkShow = .phone, motion: AutopilotArtworkMotion = .loop) -> AutopilotRun {
        var run = StudioDebugExtras.run(.ready, languages: .primary)
        run.plan.alsoMakes.setMotion(motion)
        run.plan.alsoMakes.artworkShows = shows
        return run
    }

    /// The new set's artwork full size: the header (0) or search (1).
    private static func viewer(
        _ run: AutopilotRun, at index: Int, locale: String? = nil, then: (@MainActor (ScreenshotsViewModel) -> Void)? = nil
    ) -> StudioDebugExtras.Scene {
        StudioDebugExtras.Scene(run: run, sheet: false) { model in
            model.studio.choice = .new
            if let locale { model.studio.localeCode = locale }
            StudioDebugPick.when(model) {
                $0.studio.extrasPreview?.header != nil
            } then: { model in
                model.studio.openArtwork(at: index)
                then?(model)
            }
        }
    }
}
#endif
