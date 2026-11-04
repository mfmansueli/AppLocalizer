//
//  AutopilotArtworkMaker.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

/// Renders the header and search artwork in every language with the chosen
/// direction's look, each placement's own text and the picked captures,
/// checks each render (`ArtworkChecker`: Apple's rules are errors, the rest
/// advice) and keeps each PNG in the app's Extras folder, named by its
/// checksum. An artwork-only run has no captures of its own: the set's
/// (`document`) show on the phones.
@MainActor
struct AutopilotArtworkMaker {
    let context: AutopilotContext
    var checker = ArtworkChecker()

    /// The width captures are loaded at: enough for the search image's
    /// larger phone.
    static let captureWidth = 1320

    /// Every kind in every language; `progress` gets the languages done.
    /// The PNGs and their checks go one by one; a motion run's loops draw
    /// behind them, `ArtworkLoopJob.width` at once, and a loop made before
    /// from the same poster is kept (`ArtworkLoopIndex`).
    func make(
        for run: AutopilotRun, look template: ScreenshotTemplate, texts: ArtworkTextBook, kinds: [AutopilotArtworkKind]? = nil,
        progress: (Int) -> Void
    ) async throws -> [ExtrasArtworkFile] {
        let icon = await ArtworkIcon.image(of: context.app)
        let folder = context.services.extrasFolder(for: context.app)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        var state = MakingState(index: ArtworkLoopIndex.load(from: folder), locales: run.plan.localeCodes.count)
        // Cancel Run or a failure: the loops drawn and not kept go too.
        defer {
            for draft in state.drafts { try? FileManager.default.removeItem(at: draft) }
        }
        try await withThrowingTaskGroup(of: ArtworkLoopJob.Drawn.self) { group in
            var drawing = 0
            for (localeIndex, code) in run.plan.localeCodes.enumerated() {
                try Task.checkCancellation()
                guard let locale = StoreLocaleCatalog.locale(code: code) else {
                    state.finishLocale(localeIndex)
                    continue
                }
                for kind in kinds ?? run.plan.artworkKinds {
                    let made = try await still(kind, locale: locale, run: run, look: template, texts: texts, icon: icon)
                    let fileIndex = state.files.count
                    state.files.append(made.file)
                    guard run.plan.alsoMakes.makesMotion else { continue }
                    if let kept = await keptLoop(poster: made.file.fileID, layout: made.layout, place: made.place, in: state.index) {
                        state.files[fileIndex].loop = kept.loop
                        state.files[fileIndex].checks = (made.file.checks ?? []) + kept.checks
                        continue
                    }
                    guard let layers = ArtworkLoopRenderer.layers(layout: made.layout, captures: made.captures, icon: icon) else {
                        throw ArtworkLoopError.layersFailed
                    }
                    if drawing >= ArtworkLoopJob.width, let drawn = try await group.next() {
                        drawing -= 1
                        try await keep(drawn, in: &state, folder: folder)
                    }
                    let job = ArtworkLoopJob(
                        fileIndex: fileIndex, localeIndex: localeIndex, poster: made.file.fileID, place: made.place, layout: made.layout,
                        layers: layers, draft: folder.appending(path: "loop-\(UUID().uuidString).mov")
                    )
                    state.startLoop(in: localeIndex)
                    state.drafts.insert(job.draft)
                    group.addTask { try await job.draw() }
                    drawing += 1
                }
                state.finishLocale(localeIndex)
                progress(state.localesDone)
                await Task.yield()
            }
            while let drawn = try await group.next() {
                try await keep(drawn, in: &state, folder: folder)
                progress(state.localesDone)
            }
        }
        return state.files
    }

    /// What `make` has made so far, and which languages are done: a
    /// language is done once its PNGs are and none of its loops is drawing.
    private struct MakingState {
        var index: ArtworkLoopIndex
        var files: [ExtrasArtworkFile] = []
        var drawingLoops: [Int: Int] = [:]
        var stillsDone: Set<Int> = []
        /// The loops drawing or drawn, until each is kept.
        var drafts: Set<URL> = []
        let locales: Int

        init(index: ArtworkLoopIndex, locales: Int) {
            self.index = index
            self.locales = locales
        }

        var localesDone: Int {
            stillsDone.count(where: { drawingLoops[$0, default: 0] == 0 })
        }

        mutating func startLoop(in locale: Int) { drawingLoops[locale, default: 0] += 1 }
        mutating func endLoop(in locale: Int) { drawingLoops[locale, default: 1] -= 1 }
        mutating func finishLocale(_ locale: Int) { stillsDone.insert(locale) }
    }

    /// A PNG made and checked, with what its loop needs.
    private struct Still {
        var file: ExtrasArtworkFile
        var layout: ArtworkLayout
        var captures: [Int: CGImage]
        /// "German header", for the loop's checks.
        var place: String
    }

    /// One kind in one language as a PNG in the Extras folder, checked,
    /// with what its loop needs.
    private func still(
        _ kind: AutopilotArtworkKind, locale: StoreLocale, run: AutopilotRun, look template: ScreenshotTemplate, texts: ArtworkTextBook,
        icon: CGImage?
    ) async throws -> Still {
        let services = context.services
        let code = locale.code
        let slots = Self.slots(for: kind, plan: run.plan)
        let images = await captures(slots, locale: code, run: run)
        // Each placement's own text, not a screenshot's caption.
        let headline = texts.headline(ArtworkTextRole.role(for: kind), locale: code)
        let layout = ArtworkLayoutEngine(catalog: services.fonts).layout(
            template, kind: kind, locale: locale, headline: headline, slots: slots,
            captureSizes: images.mapValues { PixelSize(width: $0.width, height: $0.height) }, appName: context.app.name,
            shows: run.plan.alsoMakes.artworkShows, isMotion: run.plan.alsoMakes.makesMotion
        )
        guard let data = ArtworkRenderer.pngData(layout: layout, captures: images, icon: icon) else {
            throw AutopilotError(String(localized: "Couldn’t render the \(kind.title.lowercased()) artwork in \(locale.name)."))
        }
        let id = ScreenshotPNG.checksum(data)
        try data.write(to: services.extrasFileURL(id, pathExtension: "png", for: context.app), options: .atomic)
        let checks = await checker.checks(ArtworkCheckInput(
            kind: kind, locale: locale, image: ScreenshotPNG.image(data), pngData: data, layout: layout, line: headline,
            template: template, screenshotTemplate: run.chosenDirection?.template
        ))
        let file = ExtrasArtworkFile(
            kind: kind, locale: code, fileID: id, headline: headline, fits: layout.headlineFits, byteCount: data.count, checks: checks
        )
        return Still(file: file, layout: layout, captures: images, place: "\(locale.name) \(kind.title.lowercased())")
    }

    /// The loop made before from the same poster, checked again; nil when
    /// there's none or its movie is gone.
    private func keptLoop(
        poster: String, layout: ArtworkLayout, place: String, in index: ArtworkLoopIndex
    ) async -> (loop: ExtrasArtworkLoop, checks: [ArtworkCheck])? {
        guard let loop = index.loop(forPoster: poster) else { return nil }
        let url = context.services.extrasFileURL(loop.fileID, pathExtension: ExtrasArtworkLoop.pathExtension, for: context.app)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return await checked(loop, at: url, layout: layout, place: place)
    }

    /// A drawn loop, named by its checksum, checked and remembered.
    private func keep(_ drawn: ArtworkLoopJob.Drawn, in state: inout MakingState, folder: URL) async throws {
        let job = drawn.job
        state.endLoop(in: job.localeIndex)
        let data = try Data(contentsOf: job.draft, options: .mappedIfSafe)
        let id = ScreenshotPNG.checksum(data)
        let url = context.services.extrasFileURL(id, pathExtension: ExtrasArtworkLoop.pathExtension, for: context.app)
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: job.draft, to: url)
        state.drafts.remove(job.draft)
        let facts = drawn.facts
        let made = ExtrasArtworkLoop(
            fileID: id, byteCount: facts.byteCount, seconds: facts.seconds, framesPerSecond: facts.framesPerSecond,
            codec: facts.codec, isSeamless: true
        )
        let kept = await checked(made, at: url, layout: job.layout, place: job.place)
        state.files[job.fileIndex].loop = kept.loop
        state.files[job.fileIndex].checks = (state.files[job.fileIndex].checks ?? []) + kept.checks
        state.index.remember(kept.loop, forPoster: job.poster)
        try? state.index.save(to: folder)
    }

    /// `loop` checked: 0:20, 30 fps, silent, no jump.
    private func checked(
        _ loop: ExtrasArtworkLoop, at url: URL, layout: ArtworkLayout, place: String
    ) async -> (loop: ExtrasArtworkLoop, checks: [ArtworkCheck]) {
        let report = await ArtworkLoopChecker.check(url, size: layout.pixelSize)
        var checked = loop
        checked.isSeamless = report.isSeamless
        return (checked, report.problems.map { ArtworkCheck(kind: .loop, severity: .error, text: "\(place): \($0)") })
    }

    /// The slots a kind's phones show, front first: the first two screens
    /// on the header, the search screen on search results.
    static func slots(for kind: AutopilotArtworkKind, plan: AutopilotPlan) -> [Int] {
        plan.artworkSlots(for: kind)
    }

    /// A screen's caption in `locale` (for the App Preview): the saved one,
    /// else the plan's in the primary language.
    static func headline(slot: Int, locale: String, plan: AutopilotPlan, captions: CaptionBook) -> String {
        if let saved = captions.caption(locale: locale, slot: slot)?.headline, !saved.isEmpty { return saved }
        guard locale == plan.primaryLocale, plan.screens.indices.contains(slot) else { return "" }
        return plan.screens[slot].caption
    }

    /// Each slot's picked iPhone capture in `locale`, else the primary
    /// language's.
    private func captures(_ slots: [Int], locale: String, run: AutopilotRun) async -> [Int: CGImage] {
        var images: [Int: CGImage] = [:]
        for slot in slots where run.plan.screens.indices.contains(slot) {
            let screen = run.plan.screens[slot].id
            let own = AutopilotCaptureTarget(screenID: screen, displayType: .iPhone, locale: locale)
            let primary = AutopilotCaptureTarget(screenID: screen, displayType: .iPhone, locale: run.plan.primaryLocale)
            guard let capture = run.finalCapture(for: own) ?? run.finalCapture(for: primary) else { continue }
            images[slot] = await context.services.captureImage(capture.screenshotCapture(slot: slot), for: context.app, pixelWidth: Self.captureWidth)
        }
        return images
    }
}
