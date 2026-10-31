//
//  AutopilotArchive.swift
//  AppLocalizer
//

import Foundation

/// Everything Autopilot keeps between launches.
struct AutopilotArchive: Codable, Hashable, Sendable {
    var runs: [StoreApp.ID: AutopilotRun] = [:]
    var designProjects: [StoreApp.ID: DesignProject] = [:]
}
