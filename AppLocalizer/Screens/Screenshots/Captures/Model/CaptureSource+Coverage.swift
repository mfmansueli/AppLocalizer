//
//  CaptureSource+Coverage.swift
//  AppLocalizer
//

import Foundation

extension CaptureSource {
    /// "fastlane", for the coverage's Source column and summary.
    var shortTitle: String {
        switch self {
        case .fastlane: String(localized: "fastlane")
        case .xcodeResults: String(localized: "Xcode")
        case .folder: String(localized: "folder")
        case .appStoreConnect: String(localized: "App Store Connect")
        }
    }
}
