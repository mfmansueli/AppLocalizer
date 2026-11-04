//
//  AutopilotRun+Concepts.swift
//  AppLocalizer
//

import Foundation

/// The header and search concepts in a run: how many it waits for, which
/// one the person chose, and the pages the set is made from. A run started
/// before concepts reads its artwork from the chosen direction, as it did.
extension AutopilotRun {
    /// The header and search come as concepts, chosen apart from the
    /// screenshot direction.
    var usesConcepts: Bool { proposesConcepts == true && !plan.artworkKinds.isEmpty }

    /// A run starts with concepts when its design source designs and it
    /// makes header or search artwork.
    static func proposesConcepts(plan: AutopilotPlan, design: DesignProjectKind) -> Bool {
        design.usesDesignAI && !plan.artworkKinds.isEmpty
    }

    /// The directions Design waits for: the Screenshot style's (three of
    /// the design source's own, one per picked template, or the kept
    /// template, which AppLocalizer adds itself), three for the App
    /// Preview's look, none when a run with concepts makes only them.
    var expectedDirections: Int { expectedDirections(concepts: usesConcepts) }

    /// The directions with or without header concepts (at Plan, before the
    /// run knows).
    func expectedDirections(concepts: Bool) -> Int {
        if plan.makesScreenshots {
            switch plan.screenshotStyle {
            case .free: return Self.directionCount
            case .templates: return max(1, plan.screenshotTemplates.count)
            case .keep: return 1
            }
        }
        if concepts, plan.previewDisplays.isEmpty { return 0 }
        return Self.directionCount
    }

    /// "3 directions · 3 headers", "1 direction", "3 headers": what Design
    /// makes, for the plan's checkpoint row.
    func designDetail(design: DesignProjectKind) -> String {
        let concepts = choosesHeader(design: design)
        let directions = expectedDirections(concepts: concepts)
        var parts: [String] = []
        if directions > 0 {
            parts.append(directions == 1 ? String(localized: "1 direction") : String(localized: "\(directions) directions"))
        }
        if concepts {
            let headers = plan.alsoMakes.conceptCount
            parts.append(headers == 1 ? String(localized: "1 header") : String(localized: "\(headers) headers"))
        }
        return parts.joined(separator: " · ")
    }

    /// The concepts Design waits for.
    var expectedConcepts: Int { usesConcepts ? plan.alsoMakes.conceptCount : 0 }

    /// Every concept, in the order it arrived.
    var conceptList: [AutopilotArtworkConcept] { concepts ?? [] }

    /// Concepts with a still page on every canvas.
    var designedConcepts: [AutopilotArtworkConcept] {
        conceptList.filter { $0.isDesigned(plan.artworkKinds) }
    }

    /// Every concept has its pages.
    var hasAllConcepts: Bool { designedConcepts.count >= expectedConcepts }

    /// Concepts still to propose or to design.
    var conceptsLeft: Int { max(expectedConcepts - designedConcepts.count, 0) }

    /// The concept with `id`, or named so.
    func concept(_ wanted: String) -> AutopilotArtworkConcept? {
        conceptList.first { $0.id == wanted } ?? conceptList.first { $0.name.localizedCaseInsensitiveCompare(wanted) == .orderedSame }
    }

    var chosenConcept: AutopilotArtworkConcept? {
        art.flatMap { id in conceptList.first { $0.id == id } }
    }

    /// The concept Claude Design recommends, else the first.
    var recommendedConcept: AutopilotArtworkConcept? {
        designedConcepts.first(where: \.isRecommended) ?? designedConcepts.first
    }

    /// The pages the set's header and search are made from: the chosen
    /// concept's (its loop's, once animated), or in a run from before the
    /// chosen direction's.
    var madeArtworkDesign: AutopilotArtworkDesign? {
        usesConcepts ? chosenConcept?.madeDesign : chosenDirection?.artworkDesign
    }

    /// The name the set's artwork goes by: the concept's, else the
    /// direction's.
    var artworkName: String? {
        usesConcepts ? chosenConcept?.name : chosenDirection?.name
    }

    /// Design and Choose show directions.
    var hasDirections: Bool { expectedDirections > 0 }

    /// The person chooses a direction: more than one comes (a kept
    /// template is the only one).
    var choosesDirection: Bool {
        hasDirections && !(plan.makesScreenshots && plan.screenshotStyle == .keep)
    }

    /// The direction Use These uses: the one picked, else the only one.
    var directionToUse: AutopilotDirection? {
        if let pick = directionPick, let direction = directions.first(where: { $0.id == pick }) { return direction }
        return choosesDirection ? nil : directions.first
    }

    /// Use These (or Use This Header) can go: a direction and a header
    /// are chosen where the run has them.
    var canUseChoices: Bool {
        (!hasDirections || directionToUse != nil) && (!usesConcepts || chosenConcept != nil)
    }

    /// The run makes a header loop from the chosen concept.
    var makesHeaderLoop: Bool { usesConcepts && plan.alsoMakes.makesMotion }

    /// "1 of 3 screenshot directions and 1 of 3 headers": what the person
    /// chooses after Design.
    var choicesTitle: String {
        var parts: [String] = []
        if choosesDirection, plan.makesScreenshots {
            let count = expectedDirections
            parts.append(count == 1 ? String(localized: "1 screenshot direction") : String(localized: "1 of \(count) screenshot directions"))
        }
        if usesConcepts {
            let count = expectedConcepts
            parts.append(count == 1 ? String(localized: "1 header") : String(localized: "1 of \(count) headers"))
        }
        return parts.joined(separator: String(localized: " and "))
    }

    /// Design's "Next, you choose: 1 of 3 screenshot directions and 1 of 3
    /// headers. Then AppLocalizer localizes, Claude Design animates the
    /// header you chose into a 20-second loop, and the App Preview is cut,
    /// for you to watch and approve."
    var nextChoiceLine: String? {
        guard usesConcepts else { return nil }
        var line = String(localized: "Next, you choose: \(choicesTitle). Then AppLocalizer localizes")
        if makesHeaderLoop {
            line += String(localized: ", \(designKind.title) animates the header you chose into a \(AutopilotArtworkMotion.loopSeconds)-second loop")
        }
        if !plan.previewDisplays.isEmpty { line += String(localized: ", and the App Preview is cut") }
        line += makesHeaderLoop || !plan.previewDisplays.isEmpty ? String(localized: ", for you to watch and approve.") : "."
        return line
    }

    /// The canvases a direction brings: none when the header and search
    /// are concepts.
    var directionArtworkKinds: [AutopilotArtworkKind] { usesConcepts ? [] : plan.artworkKinds }

    /// What a direction is, for the log: its template, or without
    /// screenshots the App Preview's look (the header and search are
    /// concepts) or the header and search.
    var directionTitle: String {
        guard usesConcepts, !plan.makesScreenshots else { return plan.directionTitle }
        return String(localized: "App Preview look")
    }

    /// "1 of 3" choices: the concepts with pages, in arrival order, for
    /// Choose.
    var conceptsToChoose: [AutopilotArtworkConcept] { designedConcepts }
}

// MARK: - The made artwork

extension AutopilotRun {
    /// The look AppLocalizer's own layout draws the artwork in where a
    /// page is missing: the chosen direction's, else the live set's.
    func artworkLook(live: ScreenshotTemplate?) -> ScreenshotTemplate? {
        chosenDirection?.artworkLook ?? live
    }

    /// Writes `design` back where `madeArtworkDesign` read it: the chosen
    /// concept's loop or stills, or the chosen direction's pages.
    mutating func setMadeArtworkDesign(_ design: AutopilotArtworkDesign) {
        if usesConcepts {
            guard let index = conceptList.firstIndex(where: { $0.id == art }) else { return }
            if concepts?[index].motion?.isEmpty == false {
                concepts?[index].motion = design
            } else {
                concepts?[index].design = design
            }
            return
        }
        guard let index = directions.firstIndex(where: { $0.id == chosenDirectionID }) else { return }
        directions[index].artworkDesign = design
    }
}
