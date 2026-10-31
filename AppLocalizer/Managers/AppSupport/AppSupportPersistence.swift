//
//  AppSupportPersistence.swift
//  AppLocalizer
//

import Foundation

/// Where `AppSupportCenter` keeps what it learned about each app.
@MainActor
protocol AppSupportPersistence {
    func load() -> AppSupportArchive
    func save(_ archive: AppSupportArchive)
}
