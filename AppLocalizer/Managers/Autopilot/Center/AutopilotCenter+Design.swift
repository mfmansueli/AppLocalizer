//
//  AutopilotCenter+Design.swift
//  AppLocalizer
//

import Foundation

/// Picking captures, and the directions: from the design AI, or made from
/// AppLocalizer's starters.
extension AutopilotCenter {
    // MARK: - Pick

    /// Picks another capture for a screen.
    func pick(_ captureID: String, for screenID: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .pick, run.candidates(for: screenID).contains(where: { $0.id == captureID }) else { return }
            run.picks[screenID] = captureID
        }
    }

    /// Use These Picks: on to Design.
    func usePicks(appID: StoreApp.ID, context: AutopilotContext) async {
        guard runs[appID]?.stage == .pick else { return }
        update(appID) { run in
            run.stage = .design
            run.handedBackAt = now()
        }
        await beginDesign(appID, context: context)
    }

    // MARK: - Design

    /// Starts Design. With no design project AppLocalizer makes the three
    /// directions itself; otherwise the design AI is asked through
    /// `next_step`.
    func beginDesign(_ appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .design else { return }
        update(appID) { run in
            let what = run.designKind.usesDesignAI
                ? String(localized: "Brief ready for \(run.designName ?? run.designKind.title): \(run.plan.screens.count) captures, \(run.plan.localeCodes.count) languages")
                : String(localized: "Making directions from AppLocalizer’s starters")
            run.appendLog(what, kind: .command, at: now())
            for line in run.plan.briefExtrasLines { run.appendLog(line, kind: .command, at: now()) }
        }
        guard !run.designKind.usesDesignAI, !holdsStages else { return }
        let directions = await StarterDirectionMaker(context: context, now: now).directions(for: run)
        for direction in directions {
            await addStarterDirection(checked(direction, of: run, context: context), appID: appID)
        }
        await advance(appID, context: context)
    }

    /// The assistant read the brief (`get_design_brief`): Design shows it's
    /// designing, and the log says so once each time the person hands the
    /// design over (Use These Picks, Ask for Changes).
    func noteBriefRead(appID: StoreApp.ID, by client: String) {
        update(appID) { run in
            guard run.stage == .design else { return }
            let handedOver = run.handedBackAt ?? run.startedAt ?? .distantPast
            let isFirst = (run.briefReadAt ?? .distantPast) < handedOver
            run.briefReadAt = now()
            guard isFirst else { return }
            let what = if run.revision != nil {
                String(localized: "\(client) read the brief and is making your changes")
            } else if run.directionsLeft == 1 {
                String(localized: "\(client) read the brief and is designing the last direction")
            } else {
                String(localized: "\(client) read the brief and is designing \(run.directionsLeft) directions")
            }
            run.appendLog(what, kind: .command, at: now())
        }
    }

    private func addStarterDirection(_ direction: AutopilotDirection, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .design else { return }
            run.directions.append(direction)
            run.appendLog(String(localized: "Direction \(run.directions.count) · \(direction.name) → template ready"), kind: .event, at: now())
        }
    }

    /// A direction from the design AI. Moves on once every one has arrived.
    func addDirection(_ direction: AutopilotDirection, appID: StoreApp.ID, context: AutopilotContext) async throws {
        guard let run = runs[appID], run.stage == .design else {
            throw AutopilotError(String(localized: "The run isn’t designing now. Call next_step to see what AppLocalizer wants."))
        }
        guard run.revision == nil else {
            throw AutopilotError(String(localized: "The person asked for changes: send them with revise_direction."))
        }
        guard !run.hasAllDirections else {
            throw AutopilotError(String(localized: "Every direction has arrived. Revise one with revise_direction when next_step asks."))
        }
        let direction = await checked(direction, of: run, context: context)
        update(appID) { run in
            run.directions.append(direction)
            run.appendLog(String(localized: "Direction \(run.directions.count) · \(direction.name) → template sent to AppLocalizer"), kind: .event, at: now())
        }
        await advance(appID, context: context)
    }

    /// Ask for Changes: the note goes back to the design AI.
    func requestRevision(_ note: String, appID: StoreApp.ID) {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        update(appID) { run in
            guard run.stage == .choose, run.designKind.usesDesignAI else { return }
            run.revision = AutopilotRevisionRequest(note: note, askedAt: now())
            run.stage = .design
            run.handedBackAt = now()
            run.appendLog(String(localized: "Asked for changes: “\(note)”"), kind: .command, at: now())
        }
    }

    /// A revised direction from the design AI: back to Choose.
    func reviseDirection(
        _ directionID: String,
        template: ScreenshotTemplate,
        extras: (artwork: ScreenshotTemplate?, preview: ScreenshotTemplate?) = (nil, nil),
        rationale: String?,
        link: String?,
        appID: StoreApp.ID,
        context: AutopilotContext
    ) async throws {
        guard let run = runs[appID], run.stage == .design, run.revision != nil else {
            throw AutopilotError(String(localized: "No change was asked for. Call next_step to see what AppLocalizer wants."))
        }
        guard run.directions.contains(where: { $0.id == directionID }) else {
            let ids = run.directions.map { "\($0.id) (\($0.name))" }.formatted(.list(type: .or))
            throw AutopilotError(String(localized: "No direction “\(directionID)” in this run; it has \(ids)."))
        }
        let checks = await AutopilotLocalizer(context: context, now: now()).directionChecks(for: template, of: run)
        update(appID) { run in
            guard let index = run.directions.firstIndex(where: { $0.id == directionID }) else { return }
            run.directions[index].template = template
            if let artwork = extras.artwork { run.directions[index].artworkTemplate = artwork }
            if let preview = extras.preview { run.directions[index].previewTemplate = preview }
            run.directions[index].isRevised = true
            run.directions[index].checks = checks
            run.directions[index].receivedAt = now()
            if let rationale, !rationale.isEmpty { run.directions[index].rationale = rationale }
            if let link, !link.isEmpty { run.directions[index].link = link }
            run.revision = nil
            run.stage = .choose
            run.appendLog(String(localized: "\(run.directions[index].name) revised → template sent to AppLocalizer"), kind: .event, at: now())
        }
    }

    /// The direction with its language checks.
    private func checked(_ direction: AutopilotDirection, of run: AutopilotRun, context: AutopilotContext) async -> AutopilotDirection {
        var direction = direction
        direction.checks = await AutopilotLocalizer(context: context, now: now()).directionChecks(for: direction.template, of: run)
        return direction
    }
}
