//
//  AutopilotNextStep+MCPConcepts.swift
//  AppLocalizer
//

import Foundation

/// `next_step` in a run with header concepts: what Design waits for (the
/// concepts, their pages, and the directions apart from them), the
/// person's note on concepts, the chosen header to animate, and the
/// person's note on the loop. The prompts themselves are added by
/// `next_step` (`ArtworkPromptBuilder`).
extension AutopilotNextStep {
    /// The concepts part of the design action.
    static func conceptsJSON(run: AutopilotRun) -> JSONValue {
        let extras = run.plan.alsoMakes
        let toAnimate = Set(run.conceptsToAnimate.map(\.id))
        let received: [JSONValue] = run.conceptList.map { concept in
            let missing = (concept.design ?? AutopilotArtworkDesign()).missing(run.plan.artworkKinds)
            var entry: [String: JSONValue] = [
                "id": .string(concept.id), "name": .string(concept.name),
                "pagesToCome": .array(missing.map { .string($0.rawValue) }),
            ]
            if run.animatesEachConcept { entry["loopToCome"] = .bool(!concept.isAnimated(run.plan.artworkKinds)) }
            // The stills its motion prompt animates.
            if toAnimate.contains(concept.id) { entry["pages"] = .object((concept.design?.pages ?? [:]).mapValues(JSONValue.string)) }
            return .object(entry)
        }
        var json: [String: JSONValue] = [
            "expected": .int(run.expectedConcepts),
            "received": .array(received),
            "style": .string(extras.artworkStyle.rawValue),
            "places": .array(run.plan.artworkKinds.map { .string($0.rawValue) }),
            "how": .string(conceptsHow(run: run)),
        ]
        if extras.artworkStyle == .templates { json["templates"] = .array(extras.headerTemplates.map { .string($0.rawValue) }) }
        return .object(json)
    }

    /// The concepts, then each one's pages.
    static func conceptsHow(run: AutopilotRun) -> String {
        let count = run.expectedConcepts
        let lead = run.conceptList.count < count
            ? "Answer the concepts prompt (prompts, id \(run.plan.alsoMakes.artworkStyle == .templates ? "artwork-concepts-templates" : "artwork-concepts-free")) "
            + "and send each of its \(count) concepts with propose_artwork_concept as soon as it's written, recommended: true on the one you recommend. "
            : ""
        let motion = run.animatesEachConcept
            ? """
             Then animate each concept's stills with its motion prompt (artwork-motion, for that concept), trying them \
            with render_artwork (concept: its id), and send them with revise_artwork_concept (concept_id, artworkDesign): \
            the person chooses among the \(AutopilotArtworkMotion.loopSeconds)-second loops.
            """
            : ""
        return lead + """
        Then make each concept's pages with its pages prompt (artwork-pages, for that concept), trying them with \
        render_artwork (concept: its id), and send them with propose_artwork_concept: concept {"id": …} and artworkDesign.
        """ + motion + """
         The concepts can be made in parallel. The header and search never go in propose_direction in this run.
        """
    }

    /// `revise` with concepts: the note, the concepts it's for, and the
    /// directions when it's for them too.
    static func reviseConceptsJSON(note: String, run: AutopilotRun) -> JSONValue {
        let revision = run.revision
        let revised = Set(revision?.revisedIDs ?? [])
        let asked = revision?.askedConcepts ?? []
        let concepts: [JSONValue] = asked.compactMap { run.concept($0) }.map { concept in
            var entry: [String: JSONValue] = [
                "id": .string(concept.id), "name": .string(concept.name),
                "revisedForThisNote": .bool(revised.contains(concept.id)),
                "artworkDesign": .object((concept.design?.pages ?? [:]).mapValues(JSONValue.string)),
            ]
            if run.animatesEachConcept { entry["animatedForThisNote"] = .bool(concept.isAnimated(run.plan.artworkKinds)) }
            return .object(entry)
        }
        var json: [String: JSONValue] = [
            "action": "revise",
            "note": .string(note),
            "concepts": .array(concepts),
            "how": .string(run.animatesEachConcept
                ? """
                Change every concept listed: its pages prompt with the note appended (prompts) says how. Send each with \
                revise_artwork_concept (concept_id, artworkDesign with the pages that change, change_notes). Then \
                animate it again from its new stills with its motion prompt (the note appended), and send those pages \
                with revise_artwork_concept too. The run goes back to the person once every concept listed has its loop.
                """
                : """
                Change every concept listed: its pages prompt with the note appended (prompts) says how. Send each with \
                revise_artwork_concept (concept_id, artworkDesign with the pages that change, change_notes), last: false on \
                all but the final one; the run goes back to the person after the last.
                """),
        ]
        if revision?.asksDirections == true, case let .object(directions) = reviseDirectionJSON(note: note, run: run) {
            json["directions"] = directions["directions"]
            json["directionsHow"] = "The note is about the screenshot directions too: revise them with revise_direction, as it says."
        }
        return .object(json)
    }

    /// `animate_header`: the chosen concept's stills to animate.
    static func animateHeaderJSON(conceptID: String, run: AutopilotRun) -> JSONValue {
        let concept = run.concept(conceptID)
        return [
            "action": "animate_header",
            "concept": .string(conceptID),
            "name": .string(concept?.name ?? conceptID),
            "pages": .object((concept?.design?.pages ?? [:]).mapValues(JSONValue.string)),
            "how": """
            Every caption and phrase is checked in every language. Animate the person's chosen header with the motion \
            prompt (prompts, artwork-motion): the same pages, with CSS animations only. Try each with render_artwork \
            (concept: its id), then send them all with revise_artwork_concept (concept_id and artworkDesign). AppLocalizer \
            checks the motion, makes the loops in every language, and the person watches them.
            """,
        ]
    }

    /// `revise_loop`: the person's note on the header loop.
    static func reviseLoopJSON(note: String, run: AutopilotRun) -> JSONValue {
        let concept = run.chosenConcept
        let review = run.loopReview
        return [
            "action": "revise_loop",
            "note": .string(note),
            "concept": .string(concept?.id ?? ""),
            "version": .int(review?.version ?? 1),
            "pages": .object((concept?.motion?.pages ?? [:]).mapValues(JSONValue.string)),
            "how": """
            The person watched the header loop and asked for changes. Change the animated pages as the motion prompt \
            with the note appended says (prompts), keeping the still and the name as approved, then send them with \
            revise_artwork_concept (concept_id, artworkDesign, change_notes). It comes back as the next version.
            """,
        ]
    }

    /// The design action's `how` when the header and search are concepts:
    /// the directions are the screenshots (and the App Preview's look)
    /// only.
    static func directionsHow(run: AutopilotRun) -> String {
        let plan = run.plan
        let remaining = max(run.expectedDirections - run.directions.count, 0)
        guard run.designKind.usesDesignAI else {
            return "AppLocalizer makes the screenshot directions from its starters; only the concepts are yours. Don't call propose_direction."
        }
        guard remaining > 0 else { return "Every screenshot direction has arrived; only the concepts are left." }
        let what = plan.makesScreenshots
            ? "the screenshots as an AppLocalizer template (template and/or ops on a base starter)"
            : "the App Preview's captions and end card, as a template"
        var line = "Call get_design_brief and send \(remaining) direction(s) with propose_direction: \(what), with no artworkDesign. "
        if plan.makesScreenshots, plan.screenshotStyle == .templates {
            let names = plan.screenshotTemplates.joined(separator: ", ")
            line += "Make one direction per template the person picked (\(names)), each named “<Template> · for <App>”, adapting the gallery template to the app. "
        }
        return line + "They arrive one by one; the person chooses one."
    }
}
