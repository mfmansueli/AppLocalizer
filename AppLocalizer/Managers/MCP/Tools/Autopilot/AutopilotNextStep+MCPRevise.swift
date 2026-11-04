//
//  AutopilotNextStep+MCPRevise.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `revise_direction`: the person's note, each direction as it is now
    /// (its template, and its header and search pages, or the artwork's own
    /// look for a direction made before them), and how to answer.
    static func reviseDirectionJSON(note: String, run: AutopilotRun?) -> JSONValue {
        let revised = Set(run?.revision?.revisedIDs ?? [])
        let extras = run?.plan.alsoMakes ?? AutopilotExtras()
        let makesScreenshots = run?.plan.makesScreenshots ?? true
        let directions: [JSONValue] = (run?.directions ?? []).map { direction in
            var item: [String: JSONValue] = [
                "id": .string(direction.id),
                "name": .string(direction.name),
                "revisedForThisNote": .bool(revised.contains(direction.id)),
            ]
            // Without screenshots, the template is only the App Preview's look.
            if makesScreenshots || extras.makesAppPreview { item["template"] = direction.template.json }
            if extras.makesArtwork {
                if let design = direction.artworkDesign, !design.isEmpty {
                    item["artworkDesign"] = .object(design.pages.mapValues(JSONValue.string))
                } else {
                    item["artwork"] = direction.artworkTemplate.map(\.json) ?? "follows template"
                }
            }
            if extras.makesAppPreview {
                item["appPreview"] = direction.previewTemplate.map(\.json) ?? "follows template"
            }
            return .object(item)
        }
        var json: [String: JSONValue] = [
            "action": "revise_direction",
            "note": .string(note),
            "directions": .array(directions),
            "how": .string(reviseHow),
        ]
        if !makesScreenshots { json["noScreenshots"] = .string(noScreenshotsHow(makesArtwork: extras.makesArtwork, makesAppPreview: extras.makesAppPreview)) }
        if extras.makesArtwork { json["artwork"] = .string(artworkHow) }
        if extras.makesMotion { json["motion"] = .string(motionHow) }
        return .object(json)
    }

    /// Every direction the note is about, one call each.
    private static let reviseHow = """
    Change every direction the note is about: all of them unless it names one. Each direction's template (and \
    artwork, appPreview) is what it is now: send only what changes, as template fields and/or ops laid on it. Send \
    each with revise_direction and this run's ID, last: false on all but the final one; the run goes back to the \
    person after the last. In rationale, say in a sentence what changed, and anything the note asked that \
    AppLocalizer can't make. A direction already revisedForThisNote doesn't need sending again.
    """

    /// A run without screenshots: the note is about what it makes.
    static func noScreenshotsHow(makesArtwork: Bool, makesAppPreview: Bool) -> String {
        switch (makesArtwork, makesAppPreview) {
        case (true, false):
            "This run makes no screenshots (the live set stays): the note is about the header and search images. Send only their pages, no template."
        case (true, true):
            """
            This run makes no screenshots (the live set stays): the note is about the header and search images and the \
            App Preview. Send their pages, and template fields only for the App Preview's captions and end card.
            """
        default:
            "This run makes no screenshots (the live set stays): the note is about the App Preview's captions and end card, its template."
        }
    }

    /// The header and search images are the direction's own pages.
    private static let artworkHow = """
    The note is about the header and search images too unless it says otherwise. A direction with artworkDesign \
    draws them from those HTML pages and nothing else: change them by sending the whole new page for each canvas \
    that changes in revise_direction's artworkDesign (the composition, illustration, typography, colors, motion: \
    anything); changing template leaves them exactly as they are. Try a page with render_artwork first. A direction \
    with artwork instead (made before pages) changes with extrasTemplates.artwork, or send artworkDesign to give it \
    pages. Words the note asks for (phrases, quotes, a slogan) go on the page as data-al="text", written once in the \
    primary language (AppLocalizer translates them). What the note asks outranks get_design_brief's advice on roles; keep its rules: the text in the safe \
    area, no prices, no awards.
    """

    /// How a page's loop moves, so a note about motion can be met.
    private static let motionHow = """
    Each header and search loop is the page's own CSS animation, stepped frame by frame: change its speed, what \
    moves and how by editing the page's @keyframes (infinite, each cycle dividing \(AutopilotArtworkMotion.loopSeconds) s). \
    The first frame is the poster, so the headline, name and icon are there from the start and stay still. A \
    direction made before pages has AppLocalizer's own fixed motion: give it pages to change that.
    """
}
