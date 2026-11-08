//
//  AutopilotCenter+HeaderLoop.swift
//  AppLocalizer
//

import Foundation

/// The header loop, with Motion loop in a run with concepts: once
/// Localize and check has every caption and phrase, the design AI animates
/// the chosen header's pages (the motion prompt), AppLocalizer makes the
/// loops from them, and the person watches them in Watch the header loop,
/// asks for changes (v2, v3…) and approves. An unattended run approves the
/// loop only when every check passes.
extension AutopilotCenter {
    /// The end of Localize and check: the extras are made and the run moves
    /// on, unless the header loop still waits for its animated pages.
    func finishLocalizing(_ appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .localize else { return }
        if run.loopReview?.isAnimating == true {
            update(appID) { run in
                guard run.loopReview?.waitsToMake == false else { return }
                run.loopReview?.waitsToMake = true
                run.handedBackAt = now()
                let name = run.chosenConcept?.name ?? ""
                run.appendLog(
                    String(localized: "Sent to \(run.designKind.title): animate the \(name) header into a \(AutopilotArtworkMotion.loopSeconds)-second loop"),
                    kind: .command, at: now()
                )
            }
            return
        }
        let extras = await makeExtras(appID, context: context)
        guard let made = runs[appID] else { return }
        finishMaking(appID, extras: extras, readyLine: Self.readyLine(for: made))
    }

    /// What the log says when the set is ready, and what isn't in Review
    /// & Push because it couldn't be made.
    static func readyLine(for run: AutopilotRun) -> String {
        let failed = run.extrasProgress?.artworkProblem == nil ? nil : run.plan.alsoMakes.artworkSize.artworkTitle
        guard run.plan.makesScreenshots else {
            if let failed {
                return String(localized: "\(failed) couldn’t be made, so it isn’t in Review & Push; Make Again tries again with what you chose")
            }
            let made = run.plan.extrasTitle ?? String(localized: "the extras")
            return String(localized: "Ready in Review & Push: \(made); the live screenshots stay as they are")
        }
        guard let failed else { return String(localized: "\(run.totalScreenshots) screenshots ready in Review & Push") }
        return String(localized: "\(run.totalScreenshots) screenshots ready in Review & Push; \(failed.lowercased()) couldn’t be made, Make Again tries again")
    }

    /// The chosen header's animated pages, from `revise_artwork_concept`:
    /// the first ones at Localize and check (then the extras are made), or
    /// a new version for the person's note at Watch the header loop (then
    /// the loops are made again).
    func addLoop(
        _ conceptID: String, design: AutopilotArtworkDesign, changeNotes: String?, client: String, appID: StoreApp.ID,
        context: AutopilotContext
    ) async throws {
        guard let run = runs[appID], let review = run.loopReview, let concept = run.chosenConcept else {
            throw AutopilotError(String(localized: "The run makes no header loop. Call next_step to see what AppLocalizer wants."))
        }
        guard concept.id == conceptID else {
            throw AutopilotError(String(localized: "The person chose \(concept.id) (\(concept.name)): animate that one."))
        }
        let pages = design.laid(over: concept.motion ?? concept.design)
        let missing = pages.missing(run.plan.artworkKinds)
        guard missing.isEmpty else {
            throw AutopilotError(String(localized: "Send the animated page for \(missing.map(\.rawValue).formatted(.list(type: .and))) too."))
        }
        switch run.stage {
        case .localize:
            guard review.isAnimating else {
                throw AutopilotError(String(localized: "The loop is already made. Call next_step to see what AppLocalizer wants."))
            }
            update(appID) { run in
                Self.setMotion(pages, of: conceptID, in: &run)
                run.loopReview?.version = 1
                run.loopReview?.waitsToMake = false
                run.appendLog(String(localized: "\(client) animated the \(concept.name) header → loop v1 sent to AppLocalizer"), kind: .event, at: now())
            }
            guard review.waitsToMake, !holdsStages else { return }
            await whileLocalizing(appID) { await finishLocalizing(appID, context: context) }
        case .watchPreview:
            try await addLoopVersion(pages, of: concept, review: review, changeNotes: changeNotes, client: client, context: context)
        default:
            throw AutopilotError(String(localized: "The run isn’t making the header loop now. Call next_step to see what AppLocalizer wants."))
        }
    }

    /// The person's note at Watch the header loop, answered: the loops
    /// made again as the next version.
    private func addLoopVersion(
        _ pages: AutopilotArtworkDesign, of concept: AutopilotArtworkConcept, review: AutopilotLoopReview, changeNotes: String?, client: String,
        context: AutopilotContext
    ) async throws {
        let appID = context.app.id
        let conceptID = concept.id
        guard let request = review.request else {
            throw AutopilotError(String(localized: "No change was asked for the header loop. Call next_step to see what AppLocalizer wants."))
        }
        guard !review.isRemaking else {
            throw AutopilotError(String(localized: "AppLocalizer is still making the loop. Call next_step in a moment."))
        }
        let version = review.version + 1
        let notes = changeNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let changes = notes.isEmpty ? request.note : notes
        update(appID) { run in
            Self.setMotion(pages, of: conceptID, in: &run)
            run.loopReview?.isRemaking = true
            run.appendLog(String(localized: "\(client) sent header loop v\(version): \(changes)"), kind: .event, at: now())
        }
        let made = await remakeLoops(appID, context: context)
        update(appID) { run in
            run.loopReview?.isRemaking = false
            run.loopReview?.request = nil
            guard made else { return }
            run.loopReview?.version = version
            run.loopReview?.revisions.append(
                AutopilotLoopRevision(version: version, changes: changes, note: request.note, client: client, madeAt: now())
            )
        }
    }

    /// The animated pages failed a motion check: true when they're refused
    /// (the first time, so the design AI fixes them), false when they're
    /// taken with the failures as a warning (after one retry).
    func refusesMotion(_ problems: [String], appID: StoreApp.ID) -> Bool {
        guard !problems.isEmpty, let review = runs[appID]?.loopReview else { return false }
        if review.motionRetries == 0 {
            update(appID) { $0.loopReview?.motionRetries = 1 }
            return true
        }
        update(appID) { run in
            run.loopReview?.motionWarnings = problems
            run.appendLog(String(localized: "Header loop taken after one retry: \(problems[0])"), kind: .problem, at: now())
        }
        return false
    }

    private static func setMotion(_ pages: AutopilotArtworkDesign, of conceptID: String, in run: inout AutopilotRun) {
        guard let index = run.conceptList.firstIndex(where: { $0.id == conceptID }) else { return }
        run.concepts?[index].motion = pages
        run.loopReview?.motionRetries = 0
    }

    /// Ask for changes on the header loop: the note goes to the design AI
    /// with the motion prompt, until `revise_artwork_concept` sends the new
    /// version.
    func requestLoopChanges(_ note: String, appID: StoreApp.ID) {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        update(appID) { run in
            guard run.stage == .watchPreview, let reviser = run.reviser, var review = run.loopReview, !review.isBusy else { return }
            review.request = AutopilotRevisionRequest(note: note, askedAt: now())
            run.loopReview = review
            run.handedBackAt = now()
            run.appendLog(String(localized: "Asked \(reviser.title) for header loop changes: “\(note)”"), kind: .command, at: now())
        }
    }

    /// The loops made again from the chosen header's new animated pages,
    /// replacing the artwork saved with the set. False when they couldn't
    /// be: the earlier ones stay.
    @discardableResult
    func remakeLoops(_ appID: StoreApp.ID, context: AutopilotContext) async -> Bool {
        await cancellably(appID) { await self.makeLoopsAgain(appID, context: context) }
    }

    private func makeLoopsAgain(_ appID: StoreApp.ID, context: AutopilotContext) async -> Bool {
        guard let run = runs[appID],
              var document = try? await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale),
              var extras = document.extras,
              let look = run.artworkLook(live: document.template) ?? Self.fallbackLook(for: context)
        else { return false }
        update(appID) { run in
            run.extrasProgress?.artworkDone = 0
            run.extrasProgress?.artworkDoneAt = nil
            run.extrasProgress?.artworkTotal = run.plan.localeCodes.count
            run.extrasProgress?.artworkChecks = []
            run.extrasProgress?.isFinished = false
        }
        let made = await makeArtwork(
            appID, run: run, look: look, texts: document.artworkTexts, live: document.template, context: context
        )
        update(appID) { $0.extrasProgress?.isFinished = true }
        guard let made, !made.isEmpty, !Task.isCancelled else {
            update(appID) { run in
                guard !Task.isCancelled else { return }
                run.appendLog(String(localized: "Couldn’t make the header loop again; the earlier one stays"), kind: .problem, at: now())
            }
            return false
        }
        extras.artwork = made
        extras.artworkDesign = run.madeArtworkDesign
        extras.madeAt = now()
        document.extras = extras
        do {
            try await context.services.saveDocument(document, for: context.app)
            return true
        } catch {
            update(appID) { run in
                run.appendLog(String(localized: "Couldn’t save the header loop: \(error.localizedDescription)"), kind: .problem, at: now())
            }
            return false
        }
    }

    /// The loop passed every check: an unattended run approves it as made.
    static func loopPasses(_ run: AutopilotRun, extras: ScreenshotExtras?) -> Bool {
        guard let artwork = extras?.artwork, !artwork.isEmpty else { return false }
        return (run.extrasProgress?.artworkChecks ?? []).isEmpty && (run.extrasProgress?.artworkTooLong ?? []).isEmpty
    }
}
