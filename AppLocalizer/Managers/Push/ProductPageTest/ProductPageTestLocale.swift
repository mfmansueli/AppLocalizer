//
//  ProductPageTestLocale.swift
//  AppLocalizer
//

import Foundation

/// One language of a test: the variant rendered for it (the treatment)
/// and, for the export, the image the page has now (the control).
struct ProductPageTestLocale: Hashable, Sendable, Identifiable {
    /// App Store Connect's locale code, e.g. `de-DE`.
    var locale: String
    var treatmentFile: URL
    var treatmentPixelSize: PixelSize
    /// The current header or search image in this language; nil when
    /// there's none to export.
    var controlFile: URL?

    var id: String { locale }
}
