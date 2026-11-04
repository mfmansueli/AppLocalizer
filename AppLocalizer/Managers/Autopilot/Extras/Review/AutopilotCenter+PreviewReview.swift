//
//  AutopilotCenter+PreviewReview.swift
//  AppLocalizer
//

import Foundation

/// Watch the App Preview, between Localize and check and Review & Push:
/// the person plays it, changes its music (made again at once, no design
/// step), asks the design source for changes (a new version: only the
/// cut, captions' size, end card and look change, the recordings stay),
/// and approves it.
extension AutopilotCenter {
    /// Localize made the extras: the person watches the App Preview when
    /// the plan stops for it and one was made; otherwise the set is ready.
    func finishMaking(_ appID: StoreApp.ID, extras: ScreenshotExtras?, readyLine: String) {
        update(appID) { run in
            guard run.stage == .localize else { return }
            if run.plan.stopsToWatchPreview, !run.plan.previewDisplays.isEmpty, extras?.hasPreviews == true {
                run.stage = .watchPreview
                if run.previewReview == nil { run.previewReview = AutopilotPreviewReview() }
                run.appendLog(String(localized: "App Preview v\(run.previewReview?.version ?? 1) ready to watch"), kind: .event, at: now())
            } else {
                run.stage = .ready
                run.finishedAt = now()
                run.appendLog(readyLine, kind: .event, at: now())
            }
        }
    }

    /// Approve App Preview: on to Review & Push.
    func approvePreview(appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .watchPreview, run.previewReview?.isBusy != true else { return }
            run.stage = .ready
            run.finishedAt = now()
            let version = run.previewReview?.version ?? 1
            run.appendLog(String(localized: "App Preview v\(version) approved · everything is in Review & Push"), kind: .event, at: now())
        }
    }

    /// Ask for changes: the note goes to the design source through
    /// `next_step`, until `revise_app_preview` sends the new version.
    func requestPreviewChanges(_ note: String, appID: StoreApp.ID) {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        update(appID) { run in
            guard run.stage == .watchPreview, run.designKind.usesDesignAI, var review = run.previewReview, !review.isBusy else { return }
            review.request = AutopilotRevisionRequest(note: note, askedAt: now())
            run.previewReview = review
            run.handedBackAt = now()
            run.appendLog(String(localized: "Asked \(run.designKind.title) for App Preview changes: “\(note)”"), kind: .command, at: now())
        }
    }

    /// The design source's new version: its cut (and optionally its look
    /// and a library track), then every App Preview is made again with it.
    func revisePreview(_ draft: AutopilotPreviewDraft, appID: StoreApp.ID, context: AutopilotContext) async throws {
        let (cut, changes, look, track, client) = (draft.cut, draft.changes, draft.look, draft.track, draft.client)
        guard let run = runs[appID], run.stage == .watchPreview, let review = run.previewReview else {
            throw AutopilotError(String(localized: "The run isn’t at Watch the App Preview. Call next_step to see what AppLocalizer wants."))
        }
        guard review.request != nil else {
            throw AutopilotError(String(localized: "No change was asked for. Call next_step to see what AppLocalizer wants."))
        }
        guard review.remake == nil else {
            throw AutopilotError(String(localized: "AppLocalizer is still making the App Preview. Call next_step in a moment."))
        }
        let ids = run.plan.screens.map(\.id)
        if let unknown = (cut.screenIDs ?? []).first(where: { !ids.contains($0) }) {
            throw AutopilotError(String(localized: "No screen “\(unknown)” in this run; it has \(ids.joined(separator: ", "))."))
        }
        if let screen = cut.endCardScreenID, !ids.contains(screen) {
            throw AutopilotError(String(localized: "No screen “\(screen)” in this run; it has \(ids.joined(separator: ", "))."))
        }
        if track == .ownFile {
            throw AutopilotError(String(localized: "Only the person can choose their own file. Pick one of the library’s tracks, or leave the music as it is."))
        }
        let version = review.version + 1
        let note = review.request?.note ?? ""
        update(appID) { run in
            run.previewReview?.cut = cut
            run.previewReview?.remake = AutopilotPreviewRemake(reason: .revision(version), total: Self.previewCount(of: run.plan))
            if let look, let index = run.directions.firstIndex(where: { $0.id == run.chosenDirectionID }) {
                run.directions[index].previewTemplate = look
            }
            if let track { run.plan.alsoMakes.previewMusic = AutopilotPreviewMusic(track: track) }
            run.appendLog(String(localized: "\(client) sent App Preview v\(version): \(changes)"), kind: .event, at: now())
        }
        let made = await remakePreviews(appID, context: context)
        update(appID) { run in
            run.previewReview?.request = nil
            guard made else { return }
            run.previewReview?.version = version
            run.previewReview?.revisions.append(
                AutopilotPreviewRevision(version: version, changes: changes, note: note, client: client, madeAt: now())
            )
        }
    }

    /// Another music: at Plan it's the plan's; at Watch the App Preview
    /// every App Preview is mixed again with it, without the design source.
    func setPreviewMusic(_ music: AutopilotPreviewMusic, appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID] else { return }
        if run.stage == .plan {
            updatePlan(for: appID) { $0.alsoMakes.previewMusic = music }
            return
        }
        guard run.stage == .watchPreview, let review = run.previewReview, !review.isBusy, run.plan.alsoMakes.previewMusic != music else { return }
        update(appID) { run in
            run.plan.alsoMakes.previewMusic = music
            run.previewReview?.remake = AutopilotPreviewRemake(reason: .music(music.title), total: Self.previewCount(of: run.plan))
            run.appendLog(String(localized: "Mixing the App Preview again with \(music.title)"), kind: .command, at: now())
        }
        if await remakePreviews(appID, context: context) {
            update(appID) { $0.appendLog(String(localized: "Mixed again with \(music.title) · music doesn’t need a design step"), kind: .event, at: now()) }
        }
    }

    /// Every App Preview made again with the run's cut, look and music,
    /// replacing the ones saved with the set. False when none could be
    /// made: the earlier ones stay.
    @discardableResult
    func remakePreviews(_ appID: StoreApp.ID, context: AutopilotContext) async -> Bool {
        await cancellably(appID) { await self.makeEveryPreviewAgain(appID, context: context) }
    }

    private func makeEveryPreviewAgain(_ appID: StoreApp.ID, context: AutopilotContext) async -> Bool {
        guard let run = runs[appID], let direction = run.chosenDirection,
              var document = try? await context.services.loadDocument(for: context.app, primaryLocale: context.primaryLocale),
              var extras = document.extras
        else {
            update(appID) { $0.previewReview?.remake = nil }
            return false
        }
        update(appID) { run in
            run.extrasProgress?.previewsDone = 0
            run.extrasProgress?.previewProblems = []
            run.extrasProgress?.previewSizes = []
        }
        let files = await makePreviews(appID, run: run, direction: direction, captions: document.captions, context: context)
        // Cancel Run: the earlier ones stay, and the run is back at its plan.
        guard !Task.isCancelled else { return false }
        guard !files.isEmpty else {
            update(appID) { run in
                run.previewReview?.remake = nil
                run.appendLog(String(localized: "Couldn’t make the App Preview again; the earlier one stays"), kind: .problem, at: now())
            }
            return false
        }
        extras.previews = files
        extras.previewTemplate = direction.previewLook
        extras.previewMusic = run.plan.alsoMakes.previewMusic
        document.extras = extras
        do {
            try await context.services.saveDocument(document, for: context.app)
        } catch {
            update(appID) { run in
                run.previewReview?.remake = nil
                run.appendLog(String(localized: "Couldn’t save the App Preview: \(error.localizedDescription)"), kind: .problem, at: now())
            }
            return false
        }
        update(appID) { $0.previewReview?.remake = nil }
        return true
    }

    /// How many App Previews the plan makes: each device in each language
    /// with its own.
    static func previewCount(of plan: AutopilotPlan) -> Int {
        plan.previewDisplays.count * plan.previewLocales.count
    }
}
