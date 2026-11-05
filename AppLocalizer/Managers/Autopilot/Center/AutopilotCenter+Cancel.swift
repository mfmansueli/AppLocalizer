//
//  AutopilotCenter+Cancel.swift
//  AppLocalizer
//

import Foundation

/// Cancel Run after Capture: whatever this Mac is making stops, and the
/// run goes back to its plan with its captures and picks, to start again.
/// Nothing reaches App Store Connect either way.
extension AutopilotCenter {
    /// The stages Cancel Run… ends; before them it's Cancel Run and Stop
    /// (`stop`), after them the set is ready.
    static let cancellableStages: Set<AutopilotStage> = [.pick, .design, .choose, .localize, .watchPreview]

    /// Back to the plan: the directions, the header concepts, the choices
    /// and what was being made are dropped; the captures and picks stay for
    /// the next start. A template version saved by Use This Direction stays
    /// in the set.
    func cancelRun(appID: StoreApp.ID) {
        guard let run = runs[appID], Self.cancellableStages.contains(run.stage) else { return }
        making.removeValue(forKey: appID)?.stop()
        update(appID) { run in
            let stage = run.stage
            Self.resetForPlan(&run)
            run.appendLog(String(localized: "Run cancelled at \(stage.title); the captures stay for the next start"), kind: .event, at: now())
        }
    }

    /// `run` as it was before it started, keeping its captures and picks.
    /// The header concepts go too: kept, they'd start the next Design with
    /// every concept in and nothing to move it on to Choose.
    static func resetForPlan(_ run: inout AutopilotRun) {
        run.stage = .plan
        run.directions = []
        run.revision = nil
        run.chosenDirectionID = nil
        run.proposesConcepts = nil
        run.animatesConcepts = nil
        run.concepts = nil
        run.art = nil
        run.directionPick = nil
        run.loopReview = nil
        run.extrasProgress = nil
        run.previewReview = nil
        run.overflows = []
        run.artworkTextNeeds = nil
        run.variantRequest = nil
        run.shortenings = []
        run.localeStatus = [:]
        run.templateVersion = nil
        run.briefReadAt = nil
        run.handedBackAt = nil
        run.finishedAt = nil
        run.problems.removeAll(where: \.isOpen)
        run.keptCaptureCount = run.keptTargetCount
    }

    /// Runs `work` so Cancel Run can stop it: cancelling cancels the task
    /// `work` runs in. The artwork, its loops and the App Previews stop at
    /// their next frame or file.
    func cancellably<T: Sendable>(_ appID: StoreApp.ID, _ work: @escaping @MainActor () async -> T) async -> T {
        let task = Task { await work() }
        let token = UUID()
        making[appID] = (token, { task.cancel() })
        defer {
            if making[appID]?.token == token { making[appID] = nil }
        }
        return await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// Counts a use of a direction or a check of every language while it
    /// goes, so a resume doesn't start a second one.
    func whileLocalizing<T>(_ appID: StoreApp.ID, _ work: () async -> T) async -> T {
        localizing[appID, default: 0] += 1
        defer { localizing[appID, default: 1] -= 1 }
        return await work()
    }
}
