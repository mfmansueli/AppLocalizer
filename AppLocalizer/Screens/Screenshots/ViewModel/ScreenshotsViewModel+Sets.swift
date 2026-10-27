//
//  ScreenshotsViewModel+Sets.swift
//  AppLocalizer
//

import CoreGraphics
import Foundation

extension ScreenshotsViewModel {
    /// The Sets groups for the current display type.
    var groups: [SetsGroup] {
        guard hasTemplate, hasCaptures else { return [] }
        var groups = [SetsGroup(
            kind: .localized, title: String(localized: "Localized Sets"), count: matrix.localizedLocales.count,
            rows: matrix.localizedLocales.compactMap(row(for:)), note: nil
        )]
        if !matrix.restoredLocales.isEmpty {
            groups.append(SetsGroup(
                kind: .restored, title: String(localized: "Restored · Not Rendered"), count: matrix.restoredLocales.count,
                rows: matrix.restoredLocales.compactMap(row(for:)),
                note: String(localized: "AppLocalizer leaves these alone until you choose Use Template Again in Locales.")
            ))
        }
        let primaryName = context.primaryLocale.name
        groups.append(SetsGroup(
            kind: .fallback, title: String(localized: "Use \(primaryName) Screenshots"), count: matrix.fallbackLocales.count,
            rows: showsFallbackRows ? matrix.fallbackLocales.compactMap(row(for:)) : [],
            note: showsFallbackRows ? nil : String(localized: "On the App Store these locales use the \(primaryName) set.")
        ))
        return groups
    }

    private func row(for code: String) -> SetsRow? {
        guard let locale = locale(code: code) else { return nil }
        let cells = matrix.row(locale: code, displayType: displayType)
        let pinnedDate = document?.scope.pinned[code]
        return SetsRow(
            locale: locale, isPrimary: code == context.primaryLocale.code,
            summary: ScreenshotRowSummary(cells: cells, restoredOn: pinnedDate), cells: cells,
            previews: live.previews(locale: code, displayType: displayType)
        )
    }

    /// The slots' header titles: "1 Today".
    var slotTitles: [(index: Int, name: String)] {
        (0..<matrix.slotCount).map { ($0, document?.slotName($0) ?? String(localized: "Slot \($0 + 1)")) }
    }

    /// On iPhone, slots 1–3 also show in search results.
    func showsInSearch(slot: Int) -> Bool {
        displayType == .iPhone && slot < 3
    }

    /// The thumbnail for a cell: its render, a live screenshot, or nil
    /// while it renders.
    func thumbnail(for cell: ScreenshotCell) -> CGImage? {
        switch cell.image {
        case let .render(job): renderQueue.images[job.key]
        case let .live(shot): renderQueue.liveImages[shot.id]
        case .none: nil
        }
    }

    /// Whether the cell waits for its render.
    func isRendering(_ cell: ScreenshotCell) -> Bool {
        guard case let .render(job) = cell.image else { return false }
        return renderQueue.images[job.key] == nil && renderQueue.isRendering
    }

    var thumbnailWidth: CGFloat { thumbnailSize.width(for: displayType) }

    /// The thumbnail height for the current display type and size.
    var thumbnailHeight: CGFloat {
        let size = pixelSize(for: displayType)
        return (thumbnailWidth * CGFloat(size.height) / CGFloat(max(1, size.width))).rounded()
    }
}
