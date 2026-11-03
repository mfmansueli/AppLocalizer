//
//  AutopilotCenter+RunChoice.swift
//  AppLocalizer
//

import Foundation

/// What "What this run makes" changes in a run: captures reused or made
/// again at Start, Capture and Pick skipped when nothing is left to capture,
/// and, without screenshots, a Localize and check that makes only the
/// header and search artwork and the App Preview, leaving the set's
/// screenshots, captions and template as they are.
extension AutopilotCenter {
    /// At Start: a new run captures again unless it reuses the last run's
    /// captures and picks. A run that was stopped keeps its own.
    func applyCaptureChoice(to run: inout AutopilotRun) {
        guard run.startedAt == nil, !run.plan.reusesCaptures else { return }
        run.captures = []
        run.picks = [:]
        run.keptCaptureCount = 0
    }

    /// Right after Start: with nothing left to capture or record (every
    /// target settled by reused captures), Capture and Pick are skipped and
    /// the run goes straight to Design with the reused picks.
    func skipCapturingIfDone(_ appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .waiting, run.remainingTargets.isEmpty, run.remainingRecordings.isEmpty,
              run.openProblems.isEmpty
        else { return }
        update(appID) { run in
            run.pickMissing()
            run.stage = .design
            run.handedBackAt = now()
            run.appendLog(Self.skippedCaptureLine(run), kind: .event, at: now())
        }
        await beginDesign(appID, context: context)
    }

    /// "Skipped capturing: reuses the Oct 28 captures and picks".
    static func skippedCaptureLine(_ run: AutopilotRun) -> String {
        guard let kept = run.keptFrom else { return String(localized: "Nothing to capture in this run") }
        let date = kept.capturedAt.formatted(.dateTime.month(.abbreviated).day())
        return String(localized: "Skipped capturing: reuses the \(date) captures and picks")
    }

    /// Without screenshots: the artwork's texts in every language, then the
    /// extras are made and the run is ready. The set is never touched.
    func checkExtrasOnly(_ appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .localize,
              let document = try? await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale)
        else { return }
        let needs = artworkTextNeeds(of: run, in: document, context: context)
        update(appID) { run in
            run.artworkTextNeeds = needs.isEmpty ? nil : needs
            guard !needs.isEmpty else { return }
            let client = run.client ?? String(localized: "the assistant")
            run.appendLog(String(localized: "Sent to \(client): \(AutopilotArtworkTextWork(needs).summary)"), kind: .command, at: now())
        }
        guard needs.isEmpty else { return }
        let extras = await makeExtras(appID, context: context)
        let what = runs[appID]?.plan.extrasTitle ?? String(localized: "the extras")
        finishMaking(appID, extras: extras, readyLine: String(localized: "Ready in Review & Push: \(what); the live screenshots stay as they are"))
    }
}
