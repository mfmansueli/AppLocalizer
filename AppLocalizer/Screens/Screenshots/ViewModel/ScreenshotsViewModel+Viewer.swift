//
//  ScreenshotsViewModel+Viewer.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotsViewModel {
    /// Opens the full-size viewer on a cell, switching to its display type.
    func openViewer(_ key: ScreenshotCellKey) {
        if displayType != key.displayType { displayType = key.displayType }
        viewer = ScreenshotViewerTarget(locale: key.locale, slot: key.slot)
    }

    /// The locales the viewer steps through: the localized sets.
    var viewerLocales: [String] { matrix.localizedLocales }

    func viewerCell(_ target: ScreenshotViewerTarget) -> ScreenshotCell? {
        matrix.cell(locale: target.locale, displayType: displayType, slot: target.slot)
    }

    /// ◀ ▶: the previous or next localized locale, wrapping around.
    func stepViewer(by offset: Int) {
        guard let viewer, !viewerLocales.isEmpty else { return }
        let index = viewerLocales.firstIndex(of: viewer.locale) ?? 0
        let next = (index + offset + viewerLocales.count) % viewerLocales.count
        self.viewer = ScreenshotViewerTarget(locale: viewerLocales[next], slot: viewer.slot)
    }

    func showInViewer(locale: String) {
        guard let viewer else { return }
        self.viewer = ScreenshotViewerTarget(locale: locale, slot: viewer.slot)
    }

    /// "2 of 12".
    func viewerPosition(_ target: ScreenshotViewerTarget) -> String {
        let index = (viewerLocales.firstIndex(of: target.locale) ?? 0) + 1
        return String(localized: "\(index) of \(viewerLocales.count)")
    }

    /// "Slot 1 · Today".
    func viewerTitle(_ target: ScreenshotViewerTarget) -> String {
        let name = document?.slotName(target.slot, on: displayType) ?? ""
        return String(localized: "Slot \(target.slot + 1) · \(name)")
    }

    /// "iPhone 6.9″ · 1320 × 2868 px · steps through the 12 localized sets".
    var viewerSubtitle: String {
        let size = pixelSize(for: displayType)
        return String(localized: "\(displayType.title) · \(size.title) px · steps through the \(viewerLocales.count) localized sets")
    }

    /// The viewer's render width in points: 262 for iPhone, 600 for iPad
    /// landscape, iPhone Duo's at the iPhone's height.
    var viewerImageWidth: CGFloat {
        displayType.thumbnailWidth(phone: 262, tablet: 600)
    }

    /// Rendered at twice the viewer's width.
    var viewerPixelWidth: Int { Int(viewerImageWidth * 2) }

    /// Open in Template Editor: the Template tab, on the viewer's locale
    /// and slot.
    func openTemplateEditor() {
        let target = viewer.map { LocaleSlot(locale: $0.locale, slot: $0.slot) }
        viewer = nil
        openTemplateEditor(at: target)
    }

    /// The Template tab, on `target` when there is one.
    func openTemplateEditor(at target: LocaleSlot?) {
        if let target { templateEditor.focus(on: target) }
        tab = .template
    }

    /// Edit Caption: the Captions tab, with the viewer's caption open in
    /// the editor.
    func editCaption() {
        let target = viewer.map { LocaleSlot(locale: $0.locale, slot: $0.slot) }
        viewer = nil
        editCaption(at: target)
    }

    /// The Captions tab, with `target`'s caption selected when there is one.
    func editCaption(at target: LocaleSlot?) {
        if let target { captions.select(target) }
        tab = .captions
    }
}
