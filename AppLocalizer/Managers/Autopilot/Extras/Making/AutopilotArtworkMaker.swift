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
    func make(
        for run: AutopilotRun, look template: ScreenshotTemplate, texts: ArtworkTextBook, kinds: [AutopilotArtworkKind]? = nil,
        progress: (Int) -> Void
    ) async throws -> [ExtrasArtworkFile] {
        let services = context.services
        let app = context.app
        let engine = ArtworkLayoutEngine(catalog: services.fonts)
        let icon = await ArtworkIcon.image(of: app)
        var files: [ExtrasArtworkFile] = []
        for (index, code) in run.plan.localeCodes.enumerated() {
            guard let locale = StoreLocaleCatalog.locale(code: code) else { continue }
            for kind in kinds ?? run.plan.artworkKinds {
                let slots = Self.slots(for: kind, plan: run.plan)
                let images = await captures(slots, locale: code, run: run)
                // Each placement's own text, not a screenshot's caption.
                let headline = texts.headline(ArtworkTextRole.role(for: kind), locale: code)
                let isMotion = run.plan.alsoMakes.makesMotion
                let layout = engine.layout(
                    template, kind: kind, locale: locale, headline: headline, slots: slots,
                    captureSizes: images.mapValues { PixelSize(width: $0.width, height: $0.height) }, appName: app.name,
                    shows: run.plan.alsoMakes.artworkShows, isMotion: isMotion
                )
                guard let data = ArtworkRenderer.pngData(layout: layout, captures: images, icon: icon) else {
                    throw AutopilotError(String(localized: "Couldn’t render the \(kind.title.lowercased()) artwork in \(locale.name)."))
                }
                let id = ScreenshotPNG.checksum(data)
                let url = services.extrasFileURL(id, pathExtension: "png", for: app)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
                var checks = await checker.checks(ArtworkCheckInput(
                    kind: kind, locale: locale, image: ScreenshotPNG.image(data), pngData: data, layout: layout, line: headline,
                    template: template, screenshotTemplate: run.chosenDirection?.template
                ))
                var loop: ExtrasArtworkLoop?
                if isMotion {
                    let made = try await makeLoop(layout: layout, captures: images, icon: icon, place: "\(locale.name) \(kind.title.lowercased())")
                    loop = made.loop
                    checks += made.checks
                }
                files.append(ExtrasArtworkFile(
                    kind: kind, locale: code, fileID: id, headline: headline, fits: layout.headlineFits, byteCount: data.count, checks: checks,
                    loop: loop
                ))
            }
            progress(index + 1)
            await Task.yield()
        }
        return files
    }

    /// The 20-second loop of a layout, written to the Extras folder under
    /// its checksum and checked: 0:20, 30 fps, silent, no jump.
    private func makeLoop(
        layout: ArtworkLayout, captures: [Int: CGImage], icon: CGImage?, place: String
    ) async throws -> (loop: ExtrasArtworkLoop, checks: [ArtworkCheck]) {
        let services = context.services
        let app = context.app
        let folder = services.extrasFolder(for: app)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let draft = folder.appending(path: "loop-\(UUID().uuidString).mov")
        let facts = try await ArtworkLoopRenderer.write(layout: layout, captures: captures, icon: icon, to: draft)
        let data = try Data(contentsOf: draft, options: .mappedIfSafe)
        let id = ScreenshotPNG.checksum(data)
        let url = services.extrasFileURL(id, pathExtension: ExtrasArtworkLoop.pathExtension, for: app)
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: draft, to: url)
        let report = await ArtworkLoopChecker.check(url, size: layout.pixelSize)
        let checks = report.problems.map { ArtworkCheck(kind: .loop, severity: .error, text: "\(place): \($0)") }
        let loop = ExtrasArtworkLoop(
            fileID: id, byteCount: facts.byteCount, seconds: facts.seconds, framesPerSecond: facts.framesPerSecond,
            codec: facts.codec, isSeamless: report.isSeamless
        )
        return (loop, checks)
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
