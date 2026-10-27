//
//  StressStripEntry.swift
//  AppLocalizer
//

import Foundation

/// One card of the stress strip: a locale that breaks layouts first, the
/// caption it's previewed with and the slot laid out in it.
struct StressStripEntry: Hashable, Sendable, Identifiable {
    var locale: StoreLocale
    var role: Role
    /// The caption shown; nil when neither the locale nor the primary has
    /// one yet.
    var caption: ScreenshotCaption?
    var captionSource: CaptionSource
    var preview: SlotPreview

    var id: String { locale.code }

    /// Why the locale is on the strip.
    enum Role: String, Hashable, Sendable {
        case primary
        /// The longest of German and Finnish on this slot, measured.
        case longest
        case rightToLeft
        case cjk

        var title: String {
            switch self {
            case .primary: String(localized: "Primary")
            case .longest: String(localized: "Longest")
            case .rightToLeft: String(localized: "Right to left")
            case .cjk: String(localized: "CJK")
            }
        }
    }

    /// Where the shown caption came from.
    enum CaptionSource: Hashable, Sendable {
        /// The locale's own caption.
        case own
        /// A translation of the primary caption, made for the preview only.
        case previewTranslation
        /// The primary caption itself, while its translation is on the way.
        case primaryStandIn
        case none
    }

    /// "Longest · preview translation".
    var roleText: String {
        switch captionSource {
        case .own, .none: role.title
        case .previewTranslation: String(localized: "\(role.title) · preview translation")
        case .primaryStandIn: String(localized: "\(role.title) · no caption yet")
        }
    }
}
