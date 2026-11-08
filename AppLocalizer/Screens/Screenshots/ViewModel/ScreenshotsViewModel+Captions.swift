//
//  ScreenshotsViewModel+Captions.swift
//  AppLocalizer
//

import Foundation

// Measuring captions with the saved template, for the Captions table and
// for translations as they arrive.
extension ScreenshotsViewModel {
    /// How `caption` fits slot `key.slot` of its locale on the current
    /// display type: the matrix's layout when it has this text, else laid
    /// out now. Nil without a template.
    func fit(of caption: ScreenshotCaption, at key: LocaleSlot) -> CaptionFit? {
        if let cell = matrix.cell(locale: key.locale, displayType: displayType, slot: key.slot),
           cell.caption?.renderText == caption.renderText, let layout = cell.layout
        {
            return layout.headline
        }
        return layout(of: caption, at: key, on: displayType)?.headline
    }

    /// Whether the caption fits on every display type templates render for
    /// this app.
    func captionFits(_ caption: ScreenshotCaption, at key: LocaleSlot) -> Bool {
        renderedDisplays.allSatisfy { display in
            layout(of: caption, at: key, on: display).map { $0.headline.fits && $0.subhead?.fits != false } ?? true
        }
    }

    private func layout(of caption: ScreenshotCaption, at key: LocaleSlot, on display: ScreenshotDisplayType) -> ScreenshotLayout? {
        guard let template = document?.template, let locale = locale(code: key.locale) else { return nil }
        return layoutEngine.layout(template, slot: key.slot, locale: locale, displayType: display, caption: caption)
    }
}
