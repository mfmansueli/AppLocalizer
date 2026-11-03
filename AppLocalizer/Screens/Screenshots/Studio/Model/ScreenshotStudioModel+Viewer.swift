//
//  ScreenshotStudioModel+Viewer.swift
//  AppLocalizer
//

import Foundation

/// The full-size viewer: a click on a screenshot, the header or search
/// artwork, a direction's screenshot or an App Preview opens it over the
/// app, with what's next to it a step away.
extension ScreenshotStudioModel {
    /// The product page's App Preview and screenshots, at `index` (the App
    /// Preview, when there is one, is first).
    func openGallery(at index: Int) {
        var items: [StudioViewerItem] = []
        if let tile = extrasPreview?.appPreview { items.append(appPreviewItem(tile.file)) }
        items += preview.shots.map { shot in
            StudioViewerItem(id: "shot.\(shot.slot)", title: shot.label, subtitle: shotSubtitle(shot), content: .shot(shot))
        }
        show(items, at: index)
    }

    /// The screenshots in search results.
    func openSearch(at index: Int) {
        let items = preview.searchShots.enumerated().map { offset, shot in
            StudioViewerItem(
                id: "search.\(shot.slot)", title: String(localized: "In search results · \(offset + 1)"),
                subtitle: shotSubtitle(shot), content: .shot(shot)
            )
        }
        show(items, at: index)
    }

    /// The header (0) and search results (1) artwork; one item when it's
    /// one 16:9 image for both.
    func openArtwork(at index: Int) {
        guard let extras = extrasPreview else { return }
        var items: [StudioViewerItem] = []
        if let header = extras.header {
            var item = artworkItem(header, title: header.kind == .wide
                ? String(localized: "Header and search results · 16:9 · \(header.kind.pixelSize.title)")
                : String(localized: "Product page header · 21:9 · \(header.kind.pixelSize.title)"))
            if header.kind == .header { item.action = .headerGuide }
            items.append(item)
        }
        if let search = extras.search, search.kind != .wide {
            items.append(artworkItem(search, title: String(localized: "Search results · 3:2 · \(search.kind.pixelSize.title)")))
        }
        show(items, at: index)
    }

    /// A direction's screenshots (then Apple Vision Pro's and Apple
    /// Watch's), at `slot`. In Review & Push's terms once it's the run's.
    func openDirection(_ direction: AutopilotDirection, at slot: Int, asNewSet: Bool = false) {
        guard let run else { return }
        let primary = StoreLocaleCatalog.locale(code: run.plan.primaryLocale)?.name ?? run.plan.primaryLocale
        let captures = pickedCaptures
        var items = layouts(for: direction).enumerated().map { offset, layout in
            let capture = captures.indices.contains(offset) ? captures[offset] : nil
            let name = run.plan.screens.indices.contains(offset) ? run.plan.screens[offset].name : ""
            return StudioViewerItem(
                id: "direction.\(offset)",
                title: asNewSet ? String(localized: "New screenshot \(offset + 1) · \(name)") : "\(direction.name) · \(offset + 1)",
                subtitle: directionSubtitle(direction, size: layout.canvas.pixelSize, display: .iPhone, language: primary, asNewSet: asNewSet),
                content: .layout(layout, capture: capture)
            )
        }
        if let vision = visionPreview(for: direction) {
            items.append(StudioViewerItem(
                id: "direction.vision", title: asNewSet ? String(localized: "New screenshot · Apple Vision Pro") : "\(direction.name) · Apple Vision Pro",
                subtitle: directionSubtitle(direction, size: vision.layout.canvas.pixelSize, display: .visionPro, language: primary, asNewSet: asNewSet),
                content: .layout(vision.layout, capture: vision.capture)
            ))
        }
        if let watch = watchPreviewCapture {
            items.append(StudioViewerItem(
                id: "direction.watch", title: String(localized: "Apple Watch capture"),
                subtitle: directionSubtitle(direction, size: watch.pixelSize, display: .watch, language: primary, asNewSet: asNewSet),
                content: .capture(watch)
            ))
        }
        show(items, at: slot)
    }

    /// One App Preview, playing in the viewer.
    func openPreview(_ file: ExtrasPreviewFile) {
        show([appPreviewItem(file)], at: 0)
    }

    func stepViewer(_ offset: Int) {
        guard var viewer else { return }
        previewPlayer.pause()
        recordingPlayer.pause()
        viewer.step(offset)
        self.viewer = viewer
    }

    func closeViewer() {
        previewPlayer.pause()
        recordingPlayer.pause()
        viewer = nil
    }

    /// The top bar's button: uses the attempt shown, or shows the part of
    /// the header iPhone shows.
    func performViewerAction(_ action: StudioViewerAction) {
        switch action {
        case let .useCapture(captureID, screenID, _, _):
            guard let run, let capture = run.candidates(for: screenID).first(where: { $0.id == captureID }) else { return }
            pick(capture, for: screenID)
            guard let index = viewer?.index, let updated = self.run else { return }
            viewer = StudioViewer(items: attemptItems(updated, screenID: screenID), index: index)
        case .headerGuide:
            viewerShowsGuide.toggle()
        }
    }

    // MARK: - Items

    func show(_ items: [StudioViewerItem], at index: Int) {
        previewPlayer.pause()
        recordingPlayer.pause()
        viewer = StudioViewer(items: items, index: index)
    }

    /// "App Preview · v2", "0:24 · ♫ Warm acoustic · click the video to
    /// play or pause".
    func appPreviewItem(_ file: ExtrasPreviewFile) -> StudioViewerItem {
        let version = run?.previewReview.map { String(localized: "App Preview · v\($0.version)") } ?? String(localized: "App Preview")
        let language = StoreLocaleCatalog.locale(code: file.locale)?.name ?? file.locale
        let music = screenshots.document?.extras?.previewMusic ?? previewMusic
        let subtitle = [
            language, file.displayType.shortTitle, file.pixelSize.title, file.lengthTitle, "♫ " + music.title,
            String(localized: "click the video to play or pause"),
        ].joined(separator: " · ")
        return StudioViewerItem(id: "appPreview.\(file.id)", title: version, subtitle: subtitle, content: .appPreview(file))
    }

    /// "Product page header · 21:9 · 3840 × 1646 · motion", "20-second
    /// loop · plays muted on repeat · English (U.S.) · New set · not pushed".
    private func artworkItem(_ item: StudioArtworkItem, title: String) -> StudioViewerItem {
        let language = StoreLocaleCatalog.locale(code: item.locale)?.name ?? item.locale
        let subtitle = [language, String(localized: "New set"), String(localized: "not pushed")].joined(separator: " · ")
        return StudioViewerItem(
            id: "artwork.\(item.kind.rawValue)", title: item.isMotion ? title + String(localized: " · motion") : title,
            subtitle: item.isMotion ? String(localized: "20-second loop · plays muted on repeat · ") + subtitle : subtitle,
            content: .artwork(item)
        )
    }

    /// "English (U.S.) · 1320 × 2868 · New set · not pushed".
    private func shotSubtitle(_ shot: StudioShot) -> String {
        let language = StoreLocaleCatalog.locale(code: selectedLocale)?.name ?? selectedLocale
        return [language, preview.displayType.title, shot.pixelSize.title, preview.note].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// "Direction from Claude Design · English (U.S.) · iPhone 6.9″ ·
    /// 1320 × 2868", or "English (U.S.) · iPhone 6.9″ · not pushed".
    private func directionSubtitle(
        _ direction: AutopilotDirection, size: PixelSize, display: ScreenshotDisplayType, language: String, asNewSet: Bool
    ) -> String {
        if asNewSet {
            return [language, display.title, size.title, String(localized: "not pushed")].joined(separator: " · ")
        }
        return [String(localized: "Direction from \(direction.sourceTitle)"), language, display.title, size.title].joined(separator: " · ")
    }
}
