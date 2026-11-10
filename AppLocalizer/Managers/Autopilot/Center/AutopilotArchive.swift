//
//  AutopilotArchive.swift
//  AppLocalizer
//

import Foundation

/// Everything Autopilot keeps between launches.
struct AutopilotArchive: Codable, Hashable, Sendable {
    var runs: [StoreApp.ID: AutopilotRun] = [:]
    var designProjects: [StoreApp.ID: DesignProject] = [:]
    /// What assistants sent for each app's next plan; nil when nothing
    /// waits, and in archives from before.
    var planProposals: [StoreApp.ID: AutopilotPlanProposals]?
}
