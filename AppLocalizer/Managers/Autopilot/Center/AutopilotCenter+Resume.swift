//
//  AutopilotCenter+Resume.swift
//  AppLocalizer
//

import Foundation

/// What this Mac was making when AppLocalizer closed: a run left at
/// Localize and check with nothing for the assistant to do, or an App
/// Preview being mixed again, picks up when the Screenshots section opens
/// or the assistant asks what's next.
extension AutopilotCenter {
    /// What a resume does for a run.
    enum Resume: Equatable {
        /// Every language checked again, then the extras made.
        case localize
        /// Use This Direction stopped before the set was saved: the choice
        /// goes back to the person.
        case chooseAgain
        /// The App Previews mixed again with the new music.
        case remix
        /// A revision's App Preview stopped: the note goes to the design
        /// source again.
        case reviseAgain
    }

    /// What to resume in `run`, when nothing on this Mac works on it
    /// (`isBusy`); nil when it's someone's turn or nothing stopped.
    static func resume(for run: AutopilotRun, isBusy: Bool) -> Resume? {
        guard !isBusy else { return nil }
        switch run.stage {
        case .localize:
            guard run.overflows.isEmpty, (run.artworkTextNeeds ?? []).isEmpty else { return nil }
            return run.plan.makesScreenshots && run.templateVersion == nil ? .chooseAgain : .localize
        case .watchPreview:
            guard let remake = run.previewReview?.remake else { return nil }
            if case .music = remake.reason { return .remix }
            return .reviseAgain
        default:
            return nil
        }
    }

    /// Picks up what stopped when AppLocalizer closed; true when something
    /// did.
    @discardableResult
    func resumeInterruptedWork(_ appID: StoreApp.ID, context: AutopilotContext) -> Bool {
        guard !holdsStages, let run = runs[appID] else { return false }
        let isBusy = making[appID] != nil || localizing[appID, default: 0] > 0
        guard let resume = Self.resume(for: run, isBusy: isBusy) else { return false }
        switch resume {
        case .localize:
            update(appID) {
                $0.appendLog(String(localized: "AppLocalizer closed while it was making them; picking up where it stopped"), kind: .event, at: now())
            }
            localizing[appID, default: 0] += 1
            Task {
                await check(appID, with: AutopilotLocalizer(context: context, now: now()))
                localizing[appID, default: 1] -= 1
            }
        case .chooseAgain:
            update(appID) { run in
                run.stage = .choose
                run.chosenDirectionID = nil
                run.localeStatus = [:]
                run.appendLog(String(localized: "AppLocalizer closed before the set was saved; choose the direction again"), kind: .event, at: now())
            }
        case .remix:
            update(appID) {
                $0.appendLog(String(localized: "AppLocalizer closed while it was mixing the App Preview; mixing it again"), kind: .event, at: now())
            }
            Task { await remakePreviews(appID, context: context) }
        case .reviseAgain:
            update(appID) { run in
                run.previewReview?.remake = nil
                let line = String(localized: "AppLocalizer closed while it was making the App Preview; your note goes to the design source again")
                run.appendLog(line, kind: .event, at: now())
            }
        }
        return true
    }
}
