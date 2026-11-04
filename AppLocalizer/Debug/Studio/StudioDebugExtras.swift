//
//  StudioDebugExtras.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Board 26's scenes, "Header, search results and App Preview":
/// - `st-plan-extras`: the plan with Also make on (21:9 and 3:2, App
///   Preview in every language) and the screens hidden.
/// - `st-choose-extras`: each direction with its header, search artwork
///   and App Preview poster.
/// - `st-loc-extras`: Localize while the artwork renders.
/// - `st-ready-extras-sheet`: Ready with their notes.
/// - `st-ready-extras`, `st-ready-extras-de` (German, dark store),
///   `st-ready-extras-wide` (Arabic, dark store, one 16:9 image): the new
///   set's App Store preview with the header, search artwork and App
///   Preview.
/// - `st-loc-extras-checks`, `st-ready-extras-checks`: the artwork done
///   with its checks: German's header has a discount (an error) and
///   Japanese's search image a Dark Mode edge (a warning).
/// - `st-ready-extras-details`: the new set's preview in German with the
///   Header and search card: German's header can't go (the discount), its
///   search image is on App Store Connect, and so is all of English's.
@MainActor
enum StudioDebugExtras {
    nonisolated static let ids = [
        "st-plan-extras", "st-choose-extras", "st-loc-extras", "st-ready-extras-sheet",
        "st-ready-extras", "st-ready-extras-de", "st-ready-extras-wide",
        "st-loc-extras-checks", "st-ready-extras-checks", "st-ready-extras-details",
    ]

    /// A scene's run, whether it opens the sheet, and the rest of its setup.
    struct Scene {
        var run: AutopilotRun
        var sheet: Bool
        var setUp: @MainActor (ScreenshotsViewModel) -> Void = { _ in }
        /// Saves what Localize made with the set.
        var savesExtras = true
        /// Changes the set further (iPhone Duo's captures, say).
        var documentChange: (@Sendable (inout ScreenshotsDocument) -> Void)?
        /// Lumen on every device: Apple Watch and Apple Vision Pro too.
        var everyDevice = false
    }

    static func scene(for id: String) -> Scene? {
        switch id {
        case "st-plan-extras":
            Scene(run: run(.plan), sheet: true) { $0.studio.showsPlanScreens = false }
        case "st-choose-extras": Scene(run: run(.choose), sheet: true)
        case "st-loc-extras": Scene(run: run(.localize), sheet: true)
        case "st-ready-extras-sheet": Scene(run: run(.ready), sheet: true)
        case "st-loc-extras-checks": Scene(run: checked(run(.localize)), sheet: true)
        case "st-ready-extras-checks": Scene(run: checked(run(.ready)), sheet: true)
        case "st-ready-extras": Scene(run: run(.ready), sheet: false) { $0.studio.choice = .new }
        case "st-ready-extras-de":
            Scene(run: run(.ready), sheet: false) { model in
                model.studio.choice = .new
                model.studio.localeCode = "de-DE"
                model.studio.appearance = .dark
            }
        case "st-ready-extras-wide":
            Scene(run: run(.ready, size: .wide), sheet: false) { model in
                model.studio.choice = .new
                model.studio.localeCode = "ar-SA"
                model.studio.appearance = .dark
            }
        default: id == "st-ready-extras-details" ? detailsScene : nil
        }
    }

    /// The debug run at `stage`, making header and search artwork and an
    /// App Preview in every language.
    static func run(
        _ stage: AutopilotStage, size: AutopilotArtworkSize = .headerAndSearch, languages: AutopilotPreviewLanguages = .all, everyDevice: Bool = false
    ) -> AutopilotRun {
        var run = StudioDebugRuns.run(stage, everyDevice: everyDevice)
        run.plan.alsoMakes = AutopilotExtras(makesArtwork: true, artworkSize: size, makesAppPreview: true, previewLanguages: languages)
        guard stage != .plan else { return run }
        let received = StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 4)
        for target in run.plan.recordingTargets where [.pick, .design, .choose, .localize, .watchPreview, .ready].contains(stage) {
            let pixelSize = target.displayType.portraitPixelSize
            run.addRecording(AutopilotRecording(
                id: "rec-\(target.displayType.mcpValue)-\(target.locale)", target: target, fileID: "debug-recording", pixelSize: pixelSize,
                seconds: 38, marks: run.plan.screens.enumerated().map { AutopilotRecordingMark(screenID: $1.id, seconds: Double($0) * 6 + 1) },
                receivedAt: received
            ))
        }
        switch stage {
        case .localize:
            var progress = AutopilotExtrasProgress()
            progress.artworkTotal = run.plan.localeCodes.count
            progress.artworkDone = 7
            progress.previewsTotal = run.plan.previewDisplays.count * run.plan.previewLocales.count
            run.extrasProgress = progress
            for code in run.plan.localeCodes { run.localeStatus[code] = .fits(note: nil) }
        case .watchPreview, .ready:
            var progress = AutopilotExtrasProgress()
            progress.artworkTotal = run.plan.localeCodes.count
            progress.artworkDone = progress.artworkTotal
            progress.previewsTotal = run.plan.previewDisplays.count * run.plan.previewLocales.count
            progress.previewsDone = progress.previewsTotal
            progress.previewSeconds = 24
            progress.previewSizes = [PixelSize(width: 886, height: 1920), PixelSize(width: 1200, height: 1600)]
            progress.isFinished = true
            run.extrasProgress = progress
        default:
            break
        }
        return run
    }

    /// The new set's preview in German with the Header and search card.
    private static var detailsScene: Scene {
        Scene(run: checked(run(.ready)), sheet: false, setUp: { model in
            model.studio.choice = .new
            model.studio.localeCode = "de-DE"
        }, documentChange: { document in
            document.extras?.pushedChecksums = pushedForDetails
        })
    }

    /// `st-ready-extras-details`' pushed files: German's search image and
    /// English's header and search.
    nonisolated static let pushedForDetails = [
        "search-de-DE": "debug-search-de-DE", "header-en-US": "debug-header-en-US", "search-en-US": "debug-search-en-US",
    ]

    /// The checks' fixtures: German's header has a discount, Japanese's
    /// search image melts into the page in Dark Mode.
    static let checks = [
        ArtworkCheck(kind: .discount, text: String(localized: "German header: ‘−50%’ — discounts and percentages aren’t allowed here.")),
        ArtworkCheck(kind: .edgeContrast, text: String(localized: "Japanese search image: its edges melt into the page in Dark Mode.")),
    ]

    /// `run` with its artwork rendered and checked.
    static func checked(_ run: AutopilotRun) -> AutopilotRun {
        var run = run
        var progress = run.extrasProgress ?? AutopilotExtrasProgress()
        progress.artworkDone = progress.artworkTotal
        progress.artworkChecks = checks
        run.extrasProgress = progress
        return run
    }

    /// What Localize saved with the set: artwork in every language (the
    /// preview draws it live), and App Previews without files (board 29's
    /// scenes make real ones: `StudioDebugPreviewMovies`).
    static func extras(for run: AutopilotRun) -> ScreenshotExtras? {
        guard run.stage == .ready || run.stage == .watchPreview, let direction = run.chosenDirection ?? run.directions.first else { return nil }
        let plan = run.plan
        var extras = ScreenshotExtras(
            directionName: direction.name, madeAt: StudioDebugRuns.date(day: 31, month: 10, hour: 14, minute: 30),
            artworkSize: plan.alsoMakes.makesArtwork ? plan.alsoMakes.artworkSize : nil, artworkTemplate: direction.artworkLook,
            searchSlot: plan.searchSlot,
            previewLanguages: plan.alsoMakes.previewLanguages, previewTemplate: direction.previewLook
        )
        extras.artworkMotion = plan.alsoMakes.artworkMotion
        extras.artworkShows = plan.alsoMakes.artworkShows
        extras.artwork = plan.localeCodes.flatMap { code in
            plan.artworkKinds.map { kind in
                ExtrasArtworkFile(kind: kind, locale: code, fileID: "debug-\(kind.rawValue)-\(code)", headline: "", fits: true, byteCount: 6_400_000)
            }
        }
        if run.extrasProgress?.artworkChecks != nil {
            for index in extras.artwork.indices {
                let file = extras.artwork[index]
                switch (file.kind, file.locale) {
                case (.header, "de-DE"): extras.artwork[index].checks = [checks[0]]
                case (.search, "ja"): extras.artwork[index].checks = [checks[1]]
                default: extras.artwork[index].checks = []
                }
            }
        }
        extras.previews = plan.previewDisplays.flatMap { display in
            plan.previewLocales.map { code in
                ExtrasPreviewFile(
                    displayType: display, locale: code, recordedLocale: code, fileID: "debug-preview-\(display.mcpValue)-\(code)", seconds: 24,
                    pixelSize: AppPreviewSpec.spec(for: display, landscape: false)?.pixelSize ?? display.portraitPixelSize,
                    byteCount: 38_000_000, posterSeconds: 5
                )
            }
        }
        return extras
    }
}
#endif
