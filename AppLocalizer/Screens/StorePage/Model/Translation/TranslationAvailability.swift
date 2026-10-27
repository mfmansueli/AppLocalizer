//
//  TranslationAvailability.swift
//  AppLocalizer
//

import Foundation

/// Whether Apple Translation can translate a language pair on this Mac.
enum TranslationAvailability: Hashable, Sendable {
    /// Both languages are downloaded.
    case ready
    /// Supported, but the languages have to be downloaded first.
    case needsDownload
    /// Apple Translation doesn't translate between these languages.
    case unsupported
}
