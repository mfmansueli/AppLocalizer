//
//  ScreenshotBackupOrigin.swift
//  AppLocalizer
//

import Foundation

/// How a kept screenshot had been made, for the restore sheet's "5 + 5
/// screenshots · uploaded by hand".
enum ScreenshotBackupOrigin: String, Codable, Hashable, Sendable {
    /// AppLocalizer had pushed it from the template.
    case template
    /// Someone uploaded it in App Store Connect.
    case uploadedByHand

    var title: String {
        switch self {
        case .template: String(localized: "from the template")
        case .uploadedByHand: String(localized: "uploaded by hand")
        }
    }
}
