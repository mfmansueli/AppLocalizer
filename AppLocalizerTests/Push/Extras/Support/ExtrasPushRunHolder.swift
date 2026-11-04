//
//  ExtrasPushRunHolder.swift
//  AppLocalizerTests
//

import Foundation
@testable import AppLocalizer

/// Lets a fake asset library reach the run it serves, e.g. to cancel it
/// while an item is in flight.
@MainActor
final class ExtrasPushRunHolder {
    var run: ExtrasPushRun?
    /// Each item's line when `noteProgress()` ran: its step, its place in
    /// line, or its status.
    var progress: [ExtrasPushItem.ID: String] = [:]
    /// Items noted as done, and whether the push was still going then.
    var noted: [(id: ExtrasPushItem.ID, whileRunning: Bool)] = []

    func cancel() {
        run?.cancelRemaining()
    }

    func noteProgress() {
        guard let run else { return }
        let now = run.environment.now()
        for item in run.items {
            progress[item.id] = run.stepDetail(of: item, now: now) ?? run.queueTitle(of: item) ?? run.status(of: item).title
        }
    }
}
