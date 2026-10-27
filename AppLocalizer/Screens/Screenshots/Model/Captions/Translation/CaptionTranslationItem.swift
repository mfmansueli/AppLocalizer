//
//  CaptionTranslationItem.swift
//  AppLocalizer
//

import Foundation

/// One empty caption to fill from the primary locale's.
struct CaptionTranslationItem: Hashable, Sendable, Identifiable {
    var key: LocaleSlot
    var locale: StoreLocale
    /// The primary locale's caption on the slot.
    var source: ScreenshotCaption
    /// Copied for a locale with the primary's language (en-US → en-GB).
    var method: TranslationMethod
    var state: TranslationItemState = .queued
    /// The caption written, once done.
    var result: ScreenshotCaption?

    var id: LocaleSlot { key }

    /// "Polish · slot 3".
    var title: String {
        String(localized: "\(locale.name) · slot \(key.slot + 1)")
    }
}
