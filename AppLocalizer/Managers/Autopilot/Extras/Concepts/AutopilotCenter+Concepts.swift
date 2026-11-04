//
//  AutopilotCenter+Concepts.swift
//  AppLocalizer
//

import Foundation

/// The header and search concepts: proposed at Design apart from the
/// screenshot directions (their idea first, their pages with it or after),
/// chosen at Choose apart from the direction, changed when the person
/// asks, and used with Use These.
extension AutopilotCenter {
    // MARK: - Design

    /// A concept from the design AI, or more of one already sent (the same
    /// id: its pages after its idea). Moves on once every concept and
    /// direction has arrived.
    @discardableResult
    func addConcept(_ concept: AutopilotArtworkConcept, appID: StoreApp.ID, context: AutopilotContext) async throws -> AutopilotArtworkConcept {
        guard let run = runs[appID], run.stage == .design, run.usesConcepts else {
            throw AutopilotError(String(localized: "The run isn’t designing header concepts now. Call next_step to see what AppLocalizer wants."))
        }
        if let revision = run.revision, revision.askedConcepts.contains(concept.id) {
            throw AutopilotError(String(localized: "The person asked for changes to this concept: send them with revise_artwork_concept."))
        }
        let existing = run.concept(concept.id)
        if existing == nil {
            guard run.conceptList.count < run.expectedConcepts else {
                let ids = run.conceptList.map { "\($0.id) (\($0.name))" }.formatted(.list(type: .and))
                throw AutopilotError(String(localized: "Every concept has arrived (\(ids)). Send more of one with its id, or revise it when next_step asks."))
            }
            try Self.checkFits(concept, in: run)
        }
        let merged = Self.merging(concept, into: existing)
        update(appID) { run in
            var list = run.conceptList
            if let index = list.firstIndex(where: { $0.id == merged.id }) {
                list[index] = merged
            } else {
                list.append(merged)
            }
            run.concepts = list
            let number = (list.firstIndex { $0.id == merged.id } ?? 0) + 1
            let what = merged.isDesigned(run.plan.artworkKinds)
                ? run.plan.alsoMakes.artworkSize.artworkTitle.lowercased()
                : String(localized: "idea")
            run.appendLog(String(localized: "Header concept \(number) · \(merged.name) → \(what) sent to AppLocalizer"), kind: .event, at: now())
        }
        await advance(appID, context: context)
        return merged
    }

    /// A concept that doesn't fit the plan: a template the person didn't
    /// pick or another concept took, or (going freely, with no request) a
    /// kind another concept has.
    static func checkFits(_ concept: AutopilotArtworkConcept, in run: AutopilotRun) throws {
        let extras = run.plan.alsoMakes
        switch extras.artworkStyle {
        case .templates:
            let picked = extras.headerTemplates
            guard let template = concept.template, picked.contains(template) else {
                let ids = picked.map(\.rawValue).formatted(.list(type: .or))
                throw AutopilotError(String(localized: "Each concept adapts one of the person’s templates: set template to \(ids)."))
            }
            if let taken = run.conceptList.first(where: { $0.template == template }) {
                let left = picked.filter { pick in !run.conceptList.contains { $0.template == pick } }.map(\.rawValue)
                throw AutopilotError(String(localized: """
                \(taken.name) already adapts \(template.rawValue): make one concept per template\
                \(left.isEmpty ? "" : ", next \(left.formatted(.list(type: .or)))").
                """))
            }
        case .free:
            guard extras.artworkDirection.isEmpty, let kind = concept.kind,
                  let same = run.conceptList.first(where: { $0.kind == kind }) else { return }
            throw AutopilotError(String(localized: """
            \(same.name) is already a \(kind.rawValue): the three concepts differ in kind (a place, a viewpoint and a wildcard).
            """))
        }
    }

    /// `concept` laid over what was sent before with its id: new words
    /// replace, pages are laid over, drafts stay until pages come.
    static func merging(_ concept: AutopilotArtworkConcept, into existing: AutopilotArtworkConcept?) -> AutopilotArtworkConcept {
        guard let existing else { return concept }
        var merged = concept
        if let design = concept.design { merged.design = design.laid(over: existing.design) } else { merged.design = existing.design }
        merged.drafts = existing.drafts
        merged.motion = existing.motion
        if concept.beats.isEmpty { merged.beats = existing.beats }
        if concept.followsTheRequest == nil { merged.followsTheRequest = existing.followsTheRequest }
        if concept.metaphor.isEmpty { merged.metaphor = existing.metaphor }
        if concept.fitsBecause.isEmpty { merged.fitsBecause = existing.fitsBecause }
        if concept.template == nil { merged.template = existing.template }
        if concept.kind == nil { merged.kind = existing.kind }
        if !concept.isRecommended { merged.isRecommended = existing.isRecommended }
        if concept.recommendedBecause == nil { merged.recommendedBecause = existing.recommendedBecause }
        return merged
    }

    /// A page render_artwork passed for a concept still without its own:
    /// the Design row shows it while the concept is designed.
    func noteConceptDraft(_ html: String, kind: AutopilotArtworkKind, conceptID: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .design, let index = run.conceptList.firstIndex(where: { $0.id == conceptID }),
                  run.conceptList[index].design?.page(for: kind) == nil
            else { return }
            var drafts = run.conceptList[index].drafts ?? AutopilotArtworkDesign()
            drafts.setPage(html, for: kind)
            run.concepts?[index].drafts = drafts
        }
    }

    /// An unattended run takes the design AI's recommended concept, and
    /// says so.
    func takeRecommendedConcept(_ appID: StoreApp.ID) {
        update(appID) { run in
            guard run.usesConcepts, run.art == nil, let concept = run.recommendedConcept else { return }
            run.art = concept.id
            let because = concept.recommendedBecause.map { ": \($0)" } ?? ""
            run.appendLog(String(localized: "Took \(run.designKind.title)’s recommended header, \(concept.name)\(because)"), kind: .event, at: now())
        }
    }

    // MARK: - Choose

    /// Choose on a concept: the header and search the set gets.
    func pickConcept(_ conceptID: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .choose, run.designedConcepts.contains(where: { $0.id == conceptID }) else { return }
            run.art = conceptID
        }
    }

    /// Choose on a direction, apart from the header.
    func pickDirection(_ directionID: String, appID: StoreApp.ID) {
        update(appID) { run in
            guard run.stage == .choose, run.directions.contains(where: { $0.id == directionID }) else { return }
            run.directionPick = directionID
        }
    }

    /// Use These (Use This Header): the picked direction and header go on
    /// to Localize, and with a motion loop the header is animated.
    func useChoices(appID: StoreApp.ID, context: AutopilotContext) async {
        guard let run = runs[appID], run.stage == .choose || run.stage == .design, run.canUseChoices else { return }
        let direction = run.directionToUse
        update(appID) { run in
            if run.makesHeaderLoop, let id = run.art { run.loopReview = AutopilotLoopReview(conceptID: id) }
            let header = run.chosenConcept?.name
            switch (direction?.name, header) {
            case let (name?, header?): run.appendLog(String(localized: "Using \(name) with the \(header) header"), kind: .event, at: now())
            case let (nil, header?): run.appendLog(String(localized: "Using the \(header) header"), kind: .event, at: now())
            default: break
            }
        }
        if let direction {
            await useDirection(direction.id, appID: appID, context: context, logs: !run.usesConcepts)
        } else {
            await useHeaderOnly(appID, context: context)
        }
    }

    /// Use This Header in a run that makes only the header and search: no
    /// direction, the live set stays.
    private func useHeaderOnly(_ appID: StoreApp.ID, context: AutopilotContext) async {
        update(appID) { run in
            run.stage = .localize
            run.handedBackAt = now()
            run.overflows = []
            run.localeStatus = Dictionary(uniqueKeysWithValues: run.plan.localeCodes.map { ($0, AutopilotLocaleStatus.waiting) })
        }
        guard !holdsStages else { return }
        await checkExtrasOnly(appID, context: context)
    }

    /// Ask for Changes on concepts: the note goes back to the design AI for
    /// `conceptIDs` (and, from the bar under them, the directions too).
    func requestConceptChanges(_ note: String, conceptIDs: [String], forDirections: Bool, appID: StoreApp.ID) {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        update(appID) { run in
            guard run.stage == .choose, run.designKind.usesDesignAI else { return }
            let ids = conceptIDs.filter { id in run.conceptList.contains { $0.id == id } }
            run.revision = AutopilotRevisionRequest(
                note: note, askedAt: now(), conceptIDs: ids.isEmpty ? nil : ids, forDirections: forDirections && run.hasDirections
            )
            run.stage = .design
            run.handedBackAt = now()
            let names = ids.compactMap { run.concept($0)?.name }
            run.appendLog(
                forDirections || names.isEmpty
                    ? String(localized: "Asked for changes: “\(note)”")
                    : String(localized: "Asked for changes to \(names.formatted(.list(type: .and))): “\(note)”"),
                kind: .command, at: now()
            )
        }
    }

    /// A concept changed for the person's note at Choose: back to Choose
    /// once every concept (and direction) the note is for has come.
    func reviseConcept(
        _ conceptID: String, design: AutopilotArtworkDesign?, changeNotes: String?, isLast: Bool, appID: StoreApp.ID
    ) throws {
        guard let run = runs[appID], run.stage == .design, let revision = run.revision else {
            throw AutopilotError(String(localized: "No change was asked for. Call next_step to see what AppLocalizer wants."))
        }
        guard revision.askedConcepts.contains(conceptID) else {
            let asked = revision.askedConcepts.compactMap { run.concept($0).map { "\($0.id) (\($0.name))" } }
            throw AutopilotError(asked.isEmpty
                ? String(localized: "The person’s note is about the screenshot directions only: send them with revise_direction.")
                : String(localized: "The person’s note is about \(asked.formatted(.list(type: .and))), not this concept."))
        }
        update(appID) { run in
            guard let index = run.conceptList.firstIndex(where: { $0.id == conceptID }) else { return }
            if let design {
                let pages = design.laid(over: run.conceptList[index].design)
                run.concepts?[index].design = pages
            }
            run.concepts?[index].isRevised = true
            run.concepts?[index].changeNotes = changeNotes
            run.concepts?[index].receivedAt = now()
            let name = run.conceptList[index].name
            var revised = run.revision?.revisedIDs ?? []
            if !revised.contains(conceptID) { revised.append(conceptID) }
            run.revision?.revisedIDs = revised
            let pending = revision.askedConcepts.filter { !revised.contains($0) }
            let what = run.plan.alsoMakes.artworkSize.artworkTitle.lowercased()
            guard isLast, pending.isEmpty, !revision.asksDirections || Self.directionsRevised(run) else {
                run.appendLog(String(localized: "\(name) revised → \(what) sent to AppLocalizer; more on the way"), kind: .event, at: now())
                return
            }
            run.revision = nil
            run.stage = .choose
            run.appendLog(String(localized: "\(name) revised → \(what) sent to AppLocalizer"), kind: .event, at: now())
        }
    }

    /// A note for the directions too has had at least one revised.
    static func directionsRevised(_ run: AutopilotRun) -> Bool {
        let revised = Set(run.revision?.revisedIDs ?? [])
        return run.directions.contains { revised.contains($0.id) }
    }
}
