//
//  AutopilotPersistence.swift
//  AppLocalizer
//

import Foundation

/// Where Autopilot's runs and design projects are kept.
@MainActor
protocol AutopilotPersistence {
    func load() -> AutopilotArchive
    func save(_ archive: AutopilotArchive)
}
