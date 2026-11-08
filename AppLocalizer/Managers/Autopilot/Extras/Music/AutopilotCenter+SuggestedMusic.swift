//
//  AutopilotCenter+SuggestedMusic.swift
//  AppLocalizer
//

import Foundation

/// The music the assistant picked from what it knows of the app, under the
/// App Preview unless the person chose one.
extension AutopilotCenter {
    /// True when the run will use `pick`: it makes an App Preview, not yet
    /// being cut, and the person hasn't chosen.
    @discardableResult
    func suggestPreviewMusic(_ pick: AppMusicPick, appID: StoreApp.ID) -> Bool {
        guard let run = runs[appID], run.plan.alsoMakes.makesAppPreview, run.plan.alsoMakes.music == nil,
              [.plan, .waiting, .capture, .pick, .design, .choose].contains(run.stage) else { return false }
        guard run.plan.alsoMakes.suggestedMusic != pick else { return true }
        update(appID) { run in
            run.plan.alsoMakes.suggestedMusic = pick
            run.appendLog(String(localized: "App Preview music picked for this app: \(pick.track.title)"), kind: .event, at: now())
        }
        return true
    }

    /// The questions went out for this run: they're asked once a run.
    func markAppQuestionsAsked(appID: StoreApp.ID) {
        update(appID) { $0.appQuestionsAskedAt = now() }
    }
}
