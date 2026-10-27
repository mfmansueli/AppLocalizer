//
//  CaptureImportError.swift
//  AppLocalizer
//

import Foundation

/// Why an import found nothing to match, or couldn't copy what it found.
enum CaptureImportError: LocalizedError, Equatable {
    /// No PNG anywhere in what was dropped or chosen.
    case noScreenshots
    /// `xcresulttool` couldn't export the bundle's attachments.
    case xcresultUnreadable(String)
    /// A file went away or can't be read between matching and Import.
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .noScreenshots:
            String(localized: """
            There are no PNG screenshots in what you chose. Choose fastlane’s screenshots folder, a folder per locale, \
            or an Xcode result bundle.
            """)
        case let .xcresultUnreadable(name):
            String(localized: "AppLocalizer couldn’t read the attachments in \(name). Export them with “xcrun xcresulttool export attachments --path \(name) --output-path <folder>” and drop that folder here.")
        case let .unreadable(path):
            String(localized: "Couldn’t read \(path). Check that the file is still there and try again.")
        }
    }
}
