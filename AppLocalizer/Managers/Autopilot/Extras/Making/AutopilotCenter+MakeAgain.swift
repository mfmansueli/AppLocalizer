//
//  AutopilotCenter+MakeAgain.swift
//  AppLocalizer
//

import Foundation

/// Make Again at Ready for review: the header and search artwork that
/// couldn't be made is made again from what the person chose, without
/// designing or choosing again. The run goes back to Localize and check,
/// every language is checked as a resume would, and it goes on from there
/// (Watch the header loop, or Ready).
extension AutopilotCenter {
    /// The artwork the run makes isn't in the set: it couldn't be made, or
    /// (runs from before `artworkProblem`) the set has none of its kinds.
    static func artworkMissing(_ run: AutopilotRun, extras: ScreenshotExtras?) -> Bool {
        let kinds = run.plan.artworkKinds
        guard run.stage == .ready, !kinds.isEmpty else { return false }
        if run.extrasProgress?.artworkProblem != nil { return true }
        guard let extras else { return false }
        return !extras.artwork.contains { kinds.contains($0.kind) }
    }

    /// Makes the missing artwork again, with everything else the run makes
    /// alongside it.
    func makeExtrasAgain(appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .ready, !run.plan.artworkKinds.isEmpty, making[appID] == nil else { return }
        update(appID) { run in
            run.stage = .localize
            run.finishedAt = nil
            run.extrasProgress = nil
            let what = run.plan.alsoMakes.artworkSize.artworkTitle.lowercased()
            run.appendLog(String(localized: "Making the \(what) again"), kind: .command, at: now())
        }
        await check(appID, with: AutopilotLocalizer(context: context, now: now()))
    }
}
