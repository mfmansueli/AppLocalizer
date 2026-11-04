//
//  ReviewPushViewModel+Viewer.swift
//  AppLocalizer
//

import Foundation

/// Review & Push's viewer: a click on a slot's live or new screenshot opens
/// that set's slots large, on that side (Live Now | New, or ↑ ↓, switches);
/// a click on a header, search image or App Preview opens its card's
/// languages, where the App Preview and a motion image play.
extension ReviewPushViewModel {
    /// A set's slots, at `item`, on `side`. `primaryLocaleName` is what a
    /// language without a set of its own shows.
    func openScreenshot(_ item: ScreenshotPlanItem, in group: ScreenshotPlanGroup, side: ReviewViewerSide, primaryLocaleName: String) {
        let items = group.items.map { Self.viewerItem($0, in: group, primaryLocaleName: primaryLocaleName) }
        viewer = ReviewViewer(items: items, index: group.items.firstIndex { $0.id == item.id } ?? 0, side: side)
    }

    /// The extras on `item`'s card: its artwork kind in every language, or
    /// every App Preview.
    func openExtra(_ item: ExtrasReviewItem, in plan: ExtrasReviewPlan) {
        let card = plan.items.filter { $0.artworkKind == item.artworkKind }
        let items = card.map { Self.viewerItem($0, musicTitle: plan.musicTitle) }
        viewer = ReviewViewer(items: items, index: card.firstIndex { $0.id == item.id } ?? 0)
    }

    func stepViewer(_ offset: Int) {
        viewer?.step(offset)
    }

    func showViewerSide(_ side: ReviewViewerSide) {
        viewer?.show(side)
    }

    func flipViewerSide() {
        viewer?.flipSide()
    }

    func closeViewer() {
        viewer = nil
    }

    // MARK: - Items

    /// "German · iPhone · 2 Week": "New · replaces what’s live · 1320 ×
    /// 2868", and on the live side "Live now on App Store Connect · 1320 ×
    /// 2868", or what shows there without one.
    static func viewerItem(_ item: ScreenshotPlanItem, in group: ScreenshotPlanGroup, primaryLocaleName: String) -> ReviewViewerItem {
        let content = ReviewViewerContent.screenshot(item)
        let change = if let date = group.restoredFrom {
            String(localized: "Kept \(date.formatted(.dateTime.month(.abbreviated).day()))")
        } else if item.old == nil {
            String(localized: "New · adds a screenshot here")
        } else {
            String(localized: "New · replaces what’s live")
        }
        let source = item.source == .you ? nil : String(localized: "from \(item.source.title)")
        let newParts = [change, content.pixelSize(.new)?.title, source].compactMap(\.self)
        let live: String = if item.old != nil {
            [String(localized: "Live now on App Store Connect"), content.pixelSize(.live)?.title].compactMap(\.self).joined(separator: " · ")
        } else if group.liveSet == nil {
            String(localized: "Nothing live: \(group.locale.name) shows \(primaryLocaleName)’s screenshots until this push")
        } else {
            String(localized: "Nothing live in this position: the push adds it")
        }
        return ReviewViewerItem(
            id: "shot.\(item.id)", title: item.title(localeName: group.locale.name), subtitle: newParts.joined(separator: " · "),
            liveSubtitle: live, content: content
        )
    }

    /// "German · Header 21:9": "3840 × 1646 · “Journal in seconds” · 20-second
    /// loop, plays muted on repeat"; an App Preview's "886 × 1920 · 0:24 ·
    /// click the video to play or pause".
    static func viewerItem(_ item: ExtrasReviewItem, musicTitle: String?) -> ReviewViewerItem {
        let kept = item.isBlocked ? String(localized: "kept out of the push") : nil
        switch item.content {
        case .artwork:
            let headline = item.headline.flatMap { $0.isEmpty ? nil : "“\($0)”" }
            let motion = item.isMotion
                ? String(localized: "\(AutopilotRun.timeTitle(Double(AutopilotArtworkMotion.loopSeconds))) loop, plays muted on repeat")
                : nil
            let parts = [item.pixelSize.title, headline, motion, kept].compactMap(\.self)
            return ReviewViewerItem(
                id: "extra.\(item.id)", title: item.title, subtitle: parts.joined(separator: " · "), content: .artwork(item)
            )
        case .appPreview:
            let file = previewFile(for: item)
            let length = file.seconds > 0 ? file.lengthTitle : nil
            let parts = [item.pixelSize.title, length, String(localized: "click the video to play or pause"), kept].compactMap(\.self)
            return ReviewViewerItem(
                id: "extra.\(item.id)", title: item.title, subtitle: parts.joined(separator: " · "),
                content: .appPreview(item, file: file, musicTitle: musicTitle)
            )
        }
    }

    /// The App Preview as it was made, or what the item knows of it (its
    /// length is then read from the movie).
    private static func previewFile(for item: ExtrasReviewItem) -> ExtrasPreviewFile {
        if let preview = item.preview { return preview }
        let display: ScreenshotDisplayType = if case let .appPreview(display, _) = item.content { display } else { .iPhone }
        return ExtrasPreviewFile(
            displayType: display, locale: item.locale, recordedLocale: item.locale, fileID: item.fileID, seconds: 0,
            pixelSize: item.pixelSize, byteCount: 0, posterSeconds: 0, problems: item.problems
        )
    }
}
