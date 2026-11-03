//
//  ExtrasReviewPlanner.swift
//  AppLocalizer
//

import Foundation

/// Turns an app's saved extras into what Review & Push lists: every
/// header, search image and App Preview not on App Store Connect yet and
/// not discarded, with its checks and the localization it goes on.
struct ExtrasReviewPlanner {
    /// Where a made file is, by checksum and extension.
    var fileURL: (_ fileID: String, _ pathExtension: String) -> URL

    func plan(appID: StoreApp.ID, appName: String, extras: ScreenshotExtras?, context: ScreenshotsContext) -> ExtrasReviewPlan? {
        guard let extras, extras.hasArtwork || extras.hasPreviews else { return nil }
        let pushed = extras.pushedChecksums ?? [:]
        let discarded = extras.discardedChecksums ?? [:]
        let localizations = Dictionary(context.localizations.map { ($0.key.code, $0.value) }, uniquingKeysWith: { first, _ in first })
        var items: [ExtrasReviewItem] = []
        var pushedCount = 0
        var discardedCount = 0
        for file in extras.artwork.sorted(by: Self.artworkOrder(primary: context.primaryLocale.code)) {
            guard pushed[file.id] != file.fileID else {
                pushedCount += 1
                continue
            }
            guard discarded[file.id] != file.fileID else {
                discardedCount += 1
                continue
            }
            items.append(ExtrasReviewItem(
                id: file.id, appID: appID, content: .artwork(file.kind), locale: file.locale, localeName: Self.name(of: file.locale),
                fileID: file.fileID, fileURL: fileURL(file.fileID, "png"), fileName: file.fileName, pixelSize: file.pixelSize, headline: file.headline,
                checks: file.checks ?? [], localizationID: localizations[file.locale],
                loopFileURL: file.loop.map { fileURL($0.fileID, ExtrasArtworkLoop.pathExtension) }
            ))
        }
        for preview in extras.previews.sorted(by: Self.previewOrder(primary: context.primaryLocale.code)) {
            guard pushed[preview.id] != preview.fileID else {
                pushedCount += 1
                continue
            }
            guard discarded[preview.id] != preview.fileID else {
                discardedCount += 1
                continue
            }
            items.append(ExtrasReviewItem(
                id: preview.id, appID: appID, content: .appPreview(preview.displayType, posterTimeCode: preview.posterTimeCode),
                locale: preview.locale, localeName: Self.name(of: preview.locale), fileID: preview.fileID,
                fileURL: fileURL(preview.fileID, "mov"), fileName: preview.fileName, pixelSize: preview.pixelSize, problems: preview.problems,
                localizationID: localizations[preview.locale]
            ))
        }
        return ExtrasReviewPlan(
            appID: appID, appName: appName, directionName: extras.directionName, items: items, pushedCount: pushedCount,
            artwork: extras.artwork, primaryLocale: context.primaryLocale.code, variant: extras.variant, discardedCount: discardedCount
        )
    }

    static func name(of code: String) -> String {
        StoreLocaleCatalog.locale(code: code)?.name ?? code
    }

    /// Primary language first, then by name; header, search, 16:9 in each.
    private static func artworkOrder(primary: String) -> (ExtrasArtworkFile, ExtrasArtworkFile) -> Bool {
        { lhs, rhs in
            if lhs.locale != rhs.locale { return localeOrder(lhs.locale, rhs.locale, primary: primary) }
            return kindIndex(lhs.kind) < kindIndex(rhs.kind)
        }
    }

    private static func previewOrder(primary: String) -> (ExtrasPreviewFile, ExtrasPreviewFile) -> Bool {
        { lhs, rhs in
            if lhs.locale != rhs.locale { return localeOrder(lhs.locale, rhs.locale, primary: primary) }
            return lhs.displayType.mcpValue < rhs.displayType.mcpValue
        }
    }

    private static func localeOrder(_ lhs: String, _ rhs: String, primary: String) -> Bool {
        if lhs == primary { return true }
        if rhs == primary { return false }
        return name(of: lhs).localizedStandardCompare(name(of: rhs)) == .orderedAscending
    }

    private static func kindIndex(_ kind: AutopilotArtworkKind) -> Int {
        AutopilotArtworkKind.allCases.firstIndex(of: kind) ?? 0
    }
}
