//
//  ScreenshotStudioModel+Concepts.swift
//  AppLocalizer
//

import Foundation

/// The header and search concepts on the Design and Choose steps: their
/// look, choosing one apart from the direction, Use These, asking for
/// changes to one, and opening one full size.
extension ScreenshotStudioModel {
    /// The look AppLocalizer's own layout draws a concept in where a page
    /// is missing: the chosen direction's, the live set's, else a plain
    /// one.
    var conceptLook: ScreenshotTemplate {
        run?.artworkLook(live: screenshots.document?.template)
            ?? ScreenshotTemplate.starter(.above, id: app.id, title: app.name, slotCount: 1)
    }

    func pickConcept(_ concept: AutopilotArtworkConcept) {
        autopilot?.pickConcept(concept.id, appID: app.id)
    }

    func pickDirection(_ direction: AutopilotDirection) {
        autopilot?.pickDirection(direction.id, appID: app.id)
    }

    /// Use These (Use This Header): the chosen direction and header go on.
    func useChoices() {
        guard let autopilot else { return }
        let context = context
        viewedStep = nil
        let appID = app.id
        let goOn = goingOn()
        Task {
            await autopilot.useChoices(appID: appID, context: context)
            await goOn()
        }
    }

    /// Ask for Changes on one concept: only that one goes back.
    func askForChanges(_ note: String, to concept: AutopilotArtworkConcept) {
        autopilot?.requestConceptChanges(note, conceptIDs: [concept.id], forDirections: false, appID: app.id)
        viewedStep = nil
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// A concept's header and search (or its one 16:9 image), full size.
    func openConcept(_ concept: AutopilotArtworkConcept, at index: Int) {
        guard let run else { return }
        let plan = run.plan
        let primary = plan.primaryLocale
        let loop = plan.alsoMakes.makesMotion
            ? String(localized: "Becomes a \(AutopilotArtworkMotion.loopSeconds)-second loop if you choose it · ")
            : ""
        let items: [StudioViewerItem] = plan.artworkKinds.map { kind in
            let page = concept.stillDesign?.page(for: kind)
            let slots = page.map(AutopilotArtworkPages.slots) ?? AutopilotArtworkMaker.slots(for: kind, plan: plan)
            let artwork = StudioArtworkItem(
                kind: kind, template: conceptLook, locale: primary,
                headline: artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary), slots: slots,
                captures: pickedCaptures(slots, run: run), shows: plan.alsoMakes.artworkShows, isMotion: false, page: page
            )
            var item = artworkItem(artwork, title: Self.conceptTitle(concept, kind: kind), subtitle: loop + concept.sourceTitle)
            item.id = "concept.\(concept.id).\(kind.rawValue)"
            if kind == .header { item.action = .headerGuide }
            return item
        }
        show(items, at: min(index, max(items.count - 1, 0)))
    }

    /// "Moonrise · header · 21:9".
    static func conceptTitle(_ concept: AutopilotArtworkConcept, kind: AutopilotArtworkKind) -> String {
        switch kind {
        case .header: String(localized: "\(concept.name) · header · 21:9")
        case .search: String(localized: "\(concept.name) · search results · 3:2")
        case .wide: String(localized: "\(concept.name) · header and search · 16:9")
        }
    }

    /// What the Choose note changes when the header and search are
    /// concepts: every concept, the directions too, and when the loop
    /// comes.
    static func conceptScopeNote(_ run: AutopilotRun) -> String {
        let what = run.hasDirections
            ? (run.plan.makesScreenshots
                ? String(localized: "A note changes the screenshot directions and every header concept: colors, type, layout and what they show.")
                : String(localized: "A note changes the App Preview’s look and every header concept: colors, type, layout and what they show."))
            : String(localized: "A note changes every header concept: colors, type, layout and what they show.")
        var line = what + " " + String(localized: "Ask for Changes… on a concept changes only that one.")
        if run.makesHeaderLoop {
            line += " " + String(localized: "The loop comes after Localize and check: you watch it and can ask for changes then.")
        }
        return line
    }

    // MARK: - Watch the header loop

    /// Ask for Changes on the header loop.
    func askForLoopChanges(_ note: String) {
        autopilot?.requestLoopChanges(note, appID: app.id)
        let goOn = goingOn()
        Task { await goOn() }
    }

    /// The loop's header and search, playing full size.
    func openLoop(at index: Int) {
        guard let run, let concept = run.chosenConcept else { return }
        let plan = run.plan
        let primary = plan.primaryLocale
        let version = run.loopReview?.version ?? 1
        let items: [StudioViewerItem] = plan.artworkKinds.map { kind in
            let page = concept.madeDesign?.page(for: kind)
            let slots = page.map(AutopilotArtworkPages.slots) ?? AutopilotArtworkMaker.slots(for: kind, plan: plan)
            let artwork = StudioArtworkItem(
                kind: kind, template: conceptLook, locale: primary,
                headline: artworkHeadline(ArtworkTextRole.role(for: kind), locale: primary), slots: slots,
                captures: pickedCaptures(slots, run: run), shows: plan.alsoMakes.artworkShows, isMotion: true, page: page
            )
            let title = switch kind {
            case .header: String(localized: "Product page header · 21:9 · 3840 × 1646 · motion")
            case .search: String(localized: "Search results · 3:2 · 3840 × 2560 · motion")
            case .wide: String(localized: "Header and search results · 16:9 · 5244 × 2950")
            }
            var item = artworkItem(artwork, title: title, subtitle: String(localized: "\(AutopilotArtworkMotion.loopSeconds)-second loop · plays muted on repeat · v\(version)"))
            item.id = "loop.\(kind.rawValue)"
            if kind == .header { item.action = .headerGuide }
            return item
        }
        show(items, at: min(index, max(items.count - 1, 0)))
    }
}
