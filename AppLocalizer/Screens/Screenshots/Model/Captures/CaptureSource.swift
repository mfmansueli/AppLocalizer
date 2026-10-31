//
//  CaptureSource.swift
//  AppLocalizer
//

import Foundation

/// Where a capture was imported from.
enum CaptureSource: String, Codable, Hashable, Sendable, CaseIterable {
    /// fastlane snapshot output: `<locale>/<device>-NN_Name.png`.
    case fastlane
    /// Screenshot attachments in an `.xcresult` per language.
    case xcodeResults
    /// A folder of PNGs matched by hand.
    case folder
    /// The screenshots live in App Store Connect; they may already have
    /// captions.
    case appStoreConnect
    /// Screenshot Autopilot: the assistant captured the app in Simulator.
    case autopilot

    var title: String {
        switch self {
        case .fastlane: String(localized: "fastlane snapshot")
        case .xcodeResults: String(localized: "Xcode test results")
        case .folder: String(localized: "Folder")
        case .appStoreConnect: String(localized: "App Store Connect")
        case .autopilot: String(localized: "Autopilot")
        }
    }
}
