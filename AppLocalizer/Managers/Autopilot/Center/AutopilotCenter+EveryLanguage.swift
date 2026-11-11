//
//  AutopilotCenter+EveryLanguage.swift
//  AppLocalizer
//

import Foundation

extension AutopilotCenter {
    /// Retry in Every Language: the problems' screen is captured again on
    /// their device in every language, once the person changed the project
    /// (see `AutopilotRun.retryInEveryLanguage`).
    func retryInEveryLanguage(appID: StoreApp.ID, problemIDs: [String], context: AutopilotContext) async {
        update(appID) { run in
            let first = run.problems.first { problemIDs.contains($0.id) }
            let added = run.retryInEveryLanguage(problemIDs, makeID: makeID, at: now())
            guard let first, added > 0 else { return }
            let name = run.plan.screen(id: first.target.screenID)?.name ?? first.target.screenID
            let count = added + problemIDs.count
            run.appendLog(
                String(localized: "\(name) on \(first.target.displayType.title): captured again in \(count) languages"),
                kind: .event, at: now()
            )
        }
        await advance(appID, context: context)
    }
}
