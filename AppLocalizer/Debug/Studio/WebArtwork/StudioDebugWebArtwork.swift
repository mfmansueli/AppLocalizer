//
//  StudioDebugWebArtwork.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The header and search designed by Claude Design as HTML pages:
/// - `st-choose-web-artwork`: Choose, each direction with its own header
///   and search pages (three different ideas, not one layout recolored).
/// - `st-ready-web-artwork`: the new set's App Store preview with Quiet
///   Indigo's pages as a loop.
/// - `st-lb-web-loop`: Quiet Indigo's header full size, its CSS motion
///   playing live.
/// - `st-lb-web-search-ar`: the search page full size in Arabic: the page
///   mirrors, the capture doesn't.
/// - `st-des-web-art-only`, `st-choose-web-art-only`: a run that makes
///   only the header and search (the live screenshots stay), at Design
///   while Claude Code makes the person's changes, and at Choose: each
///   direction shows only its pages, no screenshots.
@MainActor
enum StudioDebugWebArtwork {
    nonisolated static let ids = [
        "st-choose-web-artwork", "st-ready-web-artwork", "st-lb-web-loop", "st-lb-web-search-ar",
        "st-des-web-art-only", "st-choose-web-art-only",
    ]

    static func scene(for id: String) -> StudioDebugExtras.Scene? {
        switch id {
        case "st-choose-web-artwork":
            StudioDebugExtras.Scene(run: designed(StudioDebugExtras.run(.choose, languages: .primary)), sheet: true, savesExtras: false)
        case "st-ready-web-artwork":
            StudioDebugExtras.Scene(run: ready, sheet: false) { $0.studio.choice = .new }
        case "st-lb-web-loop":
            viewer(at: 0)
        case "st-lb-web-search-ar":
            viewer(at: 1, locale: "ar-SA")
        case "st-des-web-art-only":
            StudioDebugExtras.Scene(run: artworkOnly(.design), sheet: true, savesExtras: false)
        case "st-choose-web-art-only":
            StudioDebugExtras.Scene(run: artworkOnly(.choose), sheet: true, savesExtras: false)
        default:
            nil
        }
    }

    /// Ready with Quiet Indigo's pages, the header and search as a loop.
    static var ready: AutopilotRun {
        var run = designed(StudioDebugExtras.run(.ready, languages: .primary))
        run.plan.alsoMakes.setMotion(.loop)
        return run
    }

    /// Only the header and search, each direction with its own pages: at
    /// Choose, or back at Design with the person's note.
    static func artworkOnly(_ stage: AutopilotStage) -> AutopilotRun {
        var run = designed(StudioDebugExtras.run(.choose, languages: .primary))
        AutopilotRunPreset.headerAndSearch.apply(to: &run.plan, devices: [.iPhone, .iPad], canReuse: true)
        guard stage == .design else { return run }
        run.stage = .design
        run.revision = AutopilotRevisionRequest(
            note: "Give the phrases the whole image, and the icon's sun without its frame",
            askedAt: StudioDebugRuns.date(day: 4, month: 11, hour: 13, minute: 37)
        )
        return run
    }

    /// `run` with each direction's own header and search pages.
    static func designed(_ run: AutopilotRun) -> AutopilotRun {
        var run = run
        let pages = [quietIndigo, fullBleed, dawnPanorama]
        for index in run.directions.indices where pages.indices.contains(index) {
            run.directions[index].artworkDesign = pages[index]
        }
        return run
    }

    private static func viewer(at index: Int, locale: String? = nil) -> StudioDebugExtras.Scene {
        StudioDebugExtras.Scene(run: ready, sheet: false) { model in
            model.studio.choice = .new
            if let locale { model.studio.localeCode = locale }
            StudioDebugPick.when(model) {
                $0.studio.extrasPreview?.header != nil
            } then: { model in
                model.studio.openArtwork(at: index)
            }
        }
    }

    // MARK: - The pages

    private static func canvas(_ kind: AutopilotArtworkKind) -> String {
        "html, body { margin: 0; width: \(kind.pixelSize.width)px; height: \(kind.pixelSize.height)px; overflow: hidden; }"
    }

    /// A night sky: the name in New York over twinkling stars, and on
    /// search the phone tilted on the inline end.
    static let quietIndigo = AutopilotArtworkDesign(pages: [
        .header: """
        <!doctype html><html><head><style>
        \(canvas(.header))
        body { background: radial-gradient(120% 140% at 50% 110%, #4b3f8f 0%, #23204a 45%, #0d0c22 100%); font-family: ui-serif; color: #f4ecff; }
        .star { position: absolute; width: 10px; height: 10px; border-radius: 50%; background: #fff; animation: twinkle 4s ease-in-out infinite; }
        @keyframes twinkle { 0%, 100% { opacity: .25; } 50% { opacity: 1; } }
        .moon { position: absolute; left: 3060px; top: 300px; width: 300px; height: 300px; border-radius: 50%;
          background: radial-gradient(circle at 35% 35%, #fff8e6, #e9d9b0 70%); box-shadow: 0 0 160px 40px rgba(255, 240, 200, .25);
          animation: glow 10s ease-in-out infinite; }
        @keyframes glow { 0%, 100% { box-shadow: 0 0 160px 40px rgba(255, 240, 200, .2); } 50% { box-shadow: 0 0 220px 70px rgba(255, 240, 200, .35); } }
        .lockup { position: absolute; left: 653px; top: 620px; width: 2534px; display: flex; flex-direction: column; align-items: center; gap: 40px; }
        .row { display: flex; align-items: center; gap: 60px; }
        img[data-al="icon"] { width: 260px; height: 260px; border-radius: 58px; box-shadow: 0 30px 80px rgba(0, 0, 0, .45); }
        [data-al="appName"] { font-size: 230px; font-weight: 700; letter-spacing: -2px; }
        [data-al="headline"] { font-family: system-ui; font-size: 96px; opacity: .8; max-width: 2200px; height: 120px; text-align: center; }
        </style></head><body>
        <div class="star" style="left: 900px; top: 420px"></div><div class="star" style="left: 1400px; top: 520px; animation-delay: -1s"></div>
        <div class="star" style="left: 2100px; top: 400px; animation-delay: -2s"></div>
        <div class="star" style="left: 3000px; top: 900px; animation-delay: -3s"></div>
        <div class="moon"></div>
        <div class="lockup"><div class="row"><img data-al="icon"><div data-al="appName"></div></div>
        <div data-al="headline" data-al-fit></div></div>
        </body></html>
        """,
        .search: """
        <!doctype html><html><head><style>
        \(canvas(.search))
        body { background: linear-gradient(160deg, #1b1840 0%, #3a2f7a 55%, #6a4fb0 100%); font-family: ui-serif; color: #fbf7ff; }
        .text { position: absolute; inset-inline-start: 300px; top: 760px; width: 1700px; }
        [data-al="headline"] { font-size: 230px; font-weight: 700; line-height: 1.05; height: 760px; }
        .name { margin-top: 70px; display: flex; align-items: center; gap: 36px; font-family: system-ui; font-size: 80px; opacity: .85; }
        img[data-al="icon"] { width: 130px; height: 130px; border-radius: 29px; }
        .phone { position: absolute; inset-inline-end: 380px; top: 260px; width: 1000px; height: 2120px; border-radius: 150px;
          background: #0c0b1d; padding: 34px; box-sizing: border-box; box-shadow: 0 80px 160px rgba(0, 0, 0, .5);
          transform: rotate(-5deg); animation: float 10s ease-in-out infinite; }
        @keyframes float { 0%, 100% { translate: 0 0; } 50% { translate: 0 -40px; } }
        .phone img { width: 100%; height: 100%; border-radius: 118px; object-fit: cover; }
        </style></head><body>
        <div class="text"><div data-al="headline" data-al-fit data-al-lines="3"></div>
        <div class="name"><img data-al="icon"><span data-al="appName"></span></div></div>
        <div class="phone"><img data-al="capture" data-slot="1"></div>
        </body></html>
        """,
    ])

    /// Warm and bold: the capture in a big circle, the words over a sun.
    static let fullBleed = AutopilotArtworkDesign(pages: [
        .header: """
        <!doctype html><html><head><style>
        \(canvas(.header))
        body { background: linear-gradient(90deg, #ff7a59 0%, #ffb36b 50%, #ffd88a 100%); font-family: system-ui; color: #3b1408; }
        .sun { position: absolute; left: 1520px; top: 280px; width: 800px; height: 800px; border-radius: 50%; background: #fff2c9; opacity: .55; }
        .lockup { position: absolute; left: 653px; top: 700px; width: 2534px; text-align: center; }
        [data-al="appName"] { font-size: 300px; font-weight: 900; letter-spacing: -8px; text-transform: uppercase; }
        [data-al="headline"] { font-size: 110px; font-weight: 600; height: 140px; }
        </style></head><body><div class="sun"></div>
        <div class="lockup"><div data-al="appName"></div><div data-al="headline" data-al-fit></div></div>
        </body></html>
        """,
        .search: """
        <!doctype html><html><head><style>
        \(canvas(.search))
        body { background: #ff8a5c; font-family: system-ui; color: #2b0e05; }
        .circle { position: absolute; left: 1220px; top: 520px; width: 1400px; height: 1400px; border-radius: 50%; overflow: hidden;
          border: 40px solid #fff4e0; box-shadow: 0 60px 140px rgba(90, 30, 0, .35); }
        .circle img { width: 100%; height: 100%; object-fit: cover; object-position: top; }
        [data-al="headline"] { position: absolute; left: 240px; right: 240px; top: 150px; height: 300px; text-align: center;
          font-size: 200px; font-weight: 900; letter-spacing: -4px; }
        </style></head><body>
        <div data-al="headline" data-al-fit data-al-lines="1"></div>
        <div class="circle"><img data-al="capture" data-slot="1"></div>
        </body></html>
        """,
    ])

    /// Paper and ink: two screens side by side under a quiet line.
    static let dawnPanorama = AutopilotArtworkDesign(pages: [
        .header: """
        <!doctype html><html><head><style>
        \(canvas(.header))
        body { background: #f3eee4; font-family: 'Playfair Display', ui-serif; color: #1f2a37; }
        .rule { position: absolute; left: 653px; right: 653px; top: 1180px; height: 6px; background: #c9b896; }
        .lockup { position: absolute; left: 653px; top: 560px; width: 2534px; text-align: center; }
        [data-al="appName"] { font-size: 260px; font-style: italic; }
        [data-al="headline"] { font-family: system-ui; margin-top: 160px; font-size: 90px; letter-spacing: 12px; text-transform: uppercase; height: 120px; }
        </style></head><body><div class="rule"></div>
        <div class="lockup"><div data-al="appName"></div><div data-al="headline" data-al-fit></div></div>
        </body></html>
        """,
        .search: """
        <!doctype html><html><head><style>
        \(canvas(.search))
        body { background: linear-gradient(#f6f1e7, #e8dcc6); font-family: 'Playfair Display', ui-serif; color: #1f2a37; }
        [data-al="headline"] { position: absolute; left: 300px; right: 300px; top: 180px; height: 420px;
          text-align: center; font-size: 180px; line-height: 1.1; }
        .screens { position: absolute; left: 0; right: 0; top: 760px; display: flex; justify-content: center; gap: 120px; }
        .screens img { width: 820px; height: 1780px; object-fit: cover; object-position: top; border-radius: 90px;
          box-shadow: 0 40px 100px rgba(60, 40, 10, .25); }
        </style></head><body>
        <div data-al="headline" data-al-fit data-al-lines="2"></div>
        <div class="screens"><img data-al="capture" data-slot="1"><img data-al="capture" data-slot="2"></div>
        </body></html>
        """,
    ])
}
#endif
