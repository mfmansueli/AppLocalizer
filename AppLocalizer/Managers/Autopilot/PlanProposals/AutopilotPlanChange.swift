//
//  AutopilotPlanChange.swift
//  AppLocalizer
//

import Foundation

/// Changes to an app's capture plan the assistant sent outside a run's
/// capture (Alba's 1.1 steps, sent while its run was at Review & Push):
/// the steps of screens the plan has, the sample-data switch, the file the
/// steps come from, and the commands and notes fixes added. It waits in the
/// next plan until the person accepts or rejects it, and applies from that
/// run on.
struct AutopilotPlanChange: Codable, Hashable, Sendable, Identifiable {
    var id: String
    var client: String
    var receivedAt: Date
    /// Why, in a sentence the person reads before accepting.
    var reason: String?
    /// What shows it: a file, target or commit.
    var evidence: String?
    var screens: [AutopilotScreenStepsChange] = []
    /// How the app loads sample data, e.g. launch argument -ui-sample-week.
    var sampleData: String?
    /// The file or files the steps come from.
    var writtenFrom: String?
    /// Every command fixes added, in place of the plan's: empty removes
    /// them all.
    var setupCommands: [String]?
    /// Every note fixes left, in place of the plan's: empty removes them
    /// all.
    var setupNotes: [String]?

    var isEmpty: Bool {
        screens.isEmpty && sampleData == nil && writtenFrom == nil && setupCommands == nil && setupNotes == nil
    }

    /// What's left of this earlier change once `newer` sends the same
    /// things again: the newer one wins.
    func without(_ newer: AutopilotPlanChange) -> AutopilotPlanChange {
        var change = self
        change.screens.removeAll { screen in
            newer.screens.contains { $0.screenID == screen.screenID && $0.device == screen.device }
        }
        if newer.sampleData != nil { change.sampleData = nil }
        if newer.writtenFrom != nil { change.writtenFrom = nil }
        if newer.setupCommands != nil { change.setupCommands = nil }
        if newer.setupNotes != nil { change.setupNotes = nil }
        return change
    }

    /// Writes it into `plan`. A screen the plan no longer has is left out.
    func apply(to plan: inout AutopilotPlan) {
        for change in screens {
            guard let screen = change.screen(in: plan) else { continue }
            plan.updateScreen(id: screen.id) { $0.steps = change.steps }
        }
        if let sampleData { plan.simulator.sampleDataSteps = sampleData }
        if let writtenFrom { plan.writtenFrom = writtenFrom }
        if let setupCommands { plan.simulator.extraCommands = setupCommands }
        if let setupNotes { plan.simulator.fixNotes = setupNotes }
    }
}
