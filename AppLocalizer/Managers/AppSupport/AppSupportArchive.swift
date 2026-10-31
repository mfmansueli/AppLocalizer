//
//  AppSupportArchive.swift
//  AppLocalizer
//

import Foundation

/// Everything `AppSupportCenter` keeps between launches.
struct AppSupportArchive: Codable, Hashable, Sendable {
    var profiles: [StoreApp.ID: AppSupportProfile] = [:]
    /// Languages the person said Not Now to, by App Store locale code.
    var declinedLanguages: [StoreApp.ID: Set<String>] = [:]
}
