//
//  CaptionTranslationError.swift
//  AppLocalizer
//

import Foundation

/// Why Apple Translation can't translate a caption yet.
enum CaptionTranslationError: LocalizedError, Hashable {
    case needsDownload(StoreLocale)
    case unsupported(StoreLocale)

    var errorDescription: String? {
        switch self {
        case let .needsDownload(locale): String(localized: "\(locale.name) isn’t downloaded for Apple Translation.")
        case let .unsupported(locale): String(localized: "Apple Translation can’t translate into \(locale.name).")
        }
    }
}
