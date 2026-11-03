//
//  ProductPageTestExportResult.swift
//  AppLocalizer
//

import Foundation

/// Both variants written to a folder for a test made by hand in App Store
/// Connect, and the steps to make it.
struct ProductPageTestExportResult: Hashable, Sendable {
    var folder: URL
    /// In order: each language's control, then its treatment.
    var files: [URL]
    /// Languages without a current image to export as the control.
    var languagesWithoutControl: [String]
    /// What to do in App Store Connect, as a short paragraph.
    var steps: String
}
