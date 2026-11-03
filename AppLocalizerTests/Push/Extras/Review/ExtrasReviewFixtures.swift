//
//  ExtrasReviewFixtures.swift
//  AppLocalizerTests
//

#if DEBUG
import Foundation
@testable import AppLocalizer

/// Autopilot extras as Localize saves them: a header and a search image in
/// English, German and French, and an iPhone App Preview in English. The
/// German header carries “−50%”, an error; the English search image a
/// contrast warning.
@MainActor
enum ExtrasReviewFixtures {
    static let locales = ["en-US", "de-DE", "fr-FR"]

    static let discount = ArtworkCheck(kind: .discount, text: "German header: ‘−50%’ — discounts and percentages aren’t allowed here.")
    static let contrast = ArtworkCheck(kind: .textContrast, text: "English (U.S.) search image: the headline is hard to read (2.4:1).")

    static func extras(size: AutopilotArtworkSize = .headerAndSearch, previews: Bool = true) -> ScreenshotExtras {
        let kinds: [AutopilotArtworkKind] = size == .wide ? [.wide] : [.header, .search]
        var extras = ScreenshotExtras(
            directionName: "Calm Paper", madeAt: Date(timeIntervalSince1970: 1_800_000_000), artworkSize: size,
            artworkTemplate: ScreenshotsDebugDocuments.standard.template, previewLanguages: previews ? .primary : nil
        )
        extras.artwork = locales.flatMap { code in
            kinds.map { kind in
                var checks: [ArtworkCheck] = []
                if kind == .header, code == "de-DE" { checks = [discount] }
                if kind == .search, code == "en-US" { checks = [contrast] }
                return ExtrasArtworkFile(
                    kind: kind, locale: code, fileID: "\(kind.rawValue)-\(code)-sum", headline: kind == .header ? "" : "Journal in seconds",
                    fits: true, byteCount: 1000, checks: checks
                )
            }
        }
        if previews {
            extras.previews = [ExtrasPreviewFile(
                displayType: .iPhone, locale: "en-US", recordedLocale: "en-US", fileID: "preview-sum", seconds: 24,
                pixelSize: PixelSize(width: 886, height: 1920), byteCount: 2000, posterSeconds: 5
            )]
        }
        return extras
    }

    static func context(missing: Set<String> = []) -> ScreenshotsContext {
        ScreenshotPushTestFixtures.context(missing: missing)
    }

    static let folder = URL(filePath: "/tmp/extras")

    static var planner: ExtrasReviewPlanner {
        ExtrasReviewPlanner { id, pathExtension in folder.appending(path: "\(id).\(pathExtension)") }
    }

    static func plan(
        _ extras: ScreenshotExtras = extras(), context: ScreenshotsContext = context(), appID: StoreApp.ID = "app-1",
        planner: ExtrasReviewPlanner = planner
    ) -> ExtrasReviewPlan? {
        planner.plan(appID: appID, appName: "Lumen Journal", extras: extras, context: context)
    }

    /// The Outcome header in each language, `checks` on German's.
    static func variant(germanChecks: [ArtworkCheck] = []) -> ExtrasArtworkVariant {
        ExtrasArtworkVariant(
            role: .header, kind: .header, controlIdea: "Interface", idea: "Outcome", change: "A calm morning page instead of the editor",
            template: ScreenshotsSampleData.template,
            files: locales.map { code in
                ExtrasArtworkFile(
                    kind: .header, locale: code, fileID: "variant-header-\(code)", headline: "", fits: true, byteCount: 1000,
                    checks: code == "de-DE" ? germanChecks : []
                )
            },
            client: "Claude Code", madeAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }

    /// Writes every artwork, variant and App Preview file of `extras` into
    /// `folder`, so a push or an export can read them.
    static func writeFiles(of extras: ScreenshotExtras, into folder: URL) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in extras.artwork + (extras.variant?.files ?? []) {
            try Data("png \(file.fileID)".utf8).write(to: folder.appending(path: "\(file.fileID).png"))
        }
        for preview in extras.previews {
            try Data("mov \(preview.fileID)".utf8).write(to: folder.appending(path: "\(preview.fileID).mov"))
        }
    }
}
#endif
