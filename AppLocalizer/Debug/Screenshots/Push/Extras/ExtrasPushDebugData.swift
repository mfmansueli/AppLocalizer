//
//  ExtrasPushDebugData.swift
//  AppLocalizer
//

#if DEBUG
import CoreGraphics
import Foundation

/// What Review & Push's extras scenes show: the Ready run's header, search
/// image and App Previews with a few findings (German's header carries
/// “−50%”, which blocks it), the Outcome variant for a header test, and
/// small renders of both on disk for the thumbnails.
@MainActor
enum ExtrasPushDebugData {
    static let appID = StudioDebugRuns.appID

    /// The variant's Japanese header: a Dark Mode edge (a warning).
    private static let japaneseEdge = ArtworkCheck(
        kind: .edgeContrast, text: String(localized: "Japanese header: its edges melt into the page in Dark Mode.")
    )

    static func extras(for run: AutopilotRun, variant: Bool) -> ScreenshotExtras? {
        guard var extras = StudioDebugExtras.extras(for: run) else { return nil }
        for index in extras.artwork.indices {
            let file = extras.artwork[index]
            let locale = StoreLocaleCatalog.locale(code: file.locale)
            extras.artwork[index].headline = file.kind == .search ? (locale?.code == "de-DE" ? "Tagebuch in Sekunden" : "Journal in seconds") : ""
            extras.artwork[index].checks = checks(kind: file.kind, locale: file.locale)
        }
        if variant, let direction = run.chosenDirection ?? run.directions.first {
            var look = direction.artworkLook
            look.background.kind = .linear
            look.background.stops = ["#F6C38B", "#E9775A"]
            look.background.image = nil
            extras.variant = ExtrasArtworkVariant(
                role: .header, kind: .header, controlIdea: ArtworkVariantRequest.interface, idea: ArtworkVariantRequest.outcome,
                change: String(localized: "A calm morning page instead of the editor, warm light, no text"),
                template: look,
                files: run.plan.localeCodes.map { code in
                    ExtrasArtworkFile(
                        kind: .header, locale: code, fileID: "debug-variant-header-\(code)", headline: "", fits: true, byteCount: 6_100_000,
                        checks: code == "ja" ? [japaneseEdge] : []
                    )
                },
                client: "Claude Code", madeAt: StudioDebugRuns.date(day: 31, month: 10, hour: 15, minute: 2)
            )
        }
        return extras
    }

    /// German's header breaks a rule; English's search image and Japanese
    /// header get advice.
    private static func checks(kind: AutopilotArtworkKind, locale: String) -> [ArtworkCheck] {
        switch (kind, locale) {
        case (.header, "de-DE"):
            [ArtworkCheck(kind: .discount, text: String(localized: "German header: ‘−50%’ — discounts and percentages aren’t allowed here."))]
        case (.search, "en-US"):
            [ArtworkCheck(kind: .textContrast, text: String(localized: "English (U.S.) search image: the headline is hard to read on its background (2.4:1)."))]
        case (.header, "ja"):
            [ArtworkCheck(kind: .safeArea, text: String(localized: "Japanese header: the phones reach outside the center safe area, which some devices crop."))]
        default:
            []
        }
    }

    /// Small renders of the header and search image (and the variant) for
    /// every language's file, so the thumbnails have something to show, and
    /// a stand-in file for each App Preview, so a push can read it.
    static func writeFiles(for run: AutopilotRun, extras: ScreenshotExtras, fonts: ScreenshotFontCatalog) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "AppLocalizerAutopilot/\(appID)/Extras", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        guard let locale = StoreLocaleCatalog.locale(code: run.plan.primaryLocale), let look = extras.artworkTemplate else { return }
        let renderer = Renderer(locale: locale, captures: captures(for: run), fonts: fonts, plan: run.plan)
        var rendered: [String: Data] = [:]
        for kind in run.plan.artworkKinds {
            rendered[kind.rawValue] = renderer.render(look, kind: kind, headline: kind == .search ? "Journal in seconds" : "")
        }
        if let variant = extras.variant {
            rendered["variant"] = renderer.render(variant.template, kind: .header, headline: "")
        }
        for file in extras.artwork {
            try? rendered[file.kind.rawValue]?.write(to: folder.appending(path: "\(file.fileID).png"))
        }
        for file in extras.variant?.files ?? [] {
            try? rendered["variant"]?.write(to: folder.appending(path: "\(file.fileID).png"))
        }
        // The App Previews: stand-in bytes the simulated asset library
        // uploads without decoding.
        let video = Data(repeating: 0, count: 64 * 1024)
        for preview in extras.previews {
            try? video.write(to: folder.appending(path: "\(preview.fileID).mov"))
        }
    }

    /// Draws the artwork small, in the primary language, with the run's
    /// captures.
    @MainActor
    private struct Renderer {
        let locale: StoreLocale
        let captures: [Int: CGImage]
        let fonts: ScreenshotFontCatalog
        let plan: AutopilotPlan

        func render(_ template: ScreenshotTemplate, kind: AutopilotArtworkKind, headline: String) -> Data? {
            let slots = AutopilotArtworkMaker.slots(for: kind, plan: plan)
            let layout = ArtworkLayoutEngine(catalog: fonts).layout(
                template, kind: kind, locale: locale, headline: headline, slots: slots,
                captureSizes: captures.mapValues { PixelSize(width: $0.width, height: $0.height) }, appName: "Lumen Journal"
            )
            return ArtworkRenderer.image(layout: layout, captures: captures, pixelWidth: 960).flatMap(ScreenshotPNG.data)
        }
    }

    private static func captures(for run: AutopilotRun) -> [Int: CGImage] {
        let renderer = MockLumenCaptureRenderer()
        var images: [Int: CGImage] = [:]
        for (slot, screen) in run.plan.screens.enumerated().prefix(3) {
            let target = AutopilotCaptureTarget(screenID: screen.id, displayType: .iPhone, locale: run.plan.primaryLocale)
            guard let capture = run.finalCapture(for: target) else { continue }
            images[slot] = renderer.image(for: capture.screenshotCapture(slot: slot), pixelWidth: 400)
        }
        return images
    }
}
#endif
