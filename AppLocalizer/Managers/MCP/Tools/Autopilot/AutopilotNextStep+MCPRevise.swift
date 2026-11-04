//
//  AutopilotNextStep+MCPRevise.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `revise_direction`: the person's note, each direction as it is now
    /// (its template, and the header and search artwork's own look when it
    /// has one), what AppLocalizer can and can't change, and how to answer.
    static func reviseDirectionJSON(note: String, run: AutopilotRun?) -> JSONValue {
        let revised = Set(run?.revision?.revisedIDs ?? [])
        let extras = run?.plan.alsoMakes ?? AutopilotExtras()
        let directions: [JSONValue] = (run?.directions ?? []).map { direction in
            var item: [String: JSONValue] = [
                "id": .string(direction.id),
                "name": .string(direction.name),
                "revisedForThisNote": .bool(revised.contains(direction.id)),
                "template": direction.template.json,
            ]
            if extras.makesArtwork {
                item["artwork"] = direction.artworkTemplate.map(\.json) ?? "follows template"
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
        if extras.makesArtwork { json["artwork"] = .string(artworkHow) }
        if extras.makesMotion { json["motion"] = .string(motionFacts) }
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

    /// The header and search images have a look of their own.
    private static let artworkHow = """
    The note is about the header and search images too unless it says otherwise. A direction whose artwork is a \
    template draws them from it: change them in extrasTemplates.artwork (fields and/or ops, laid on that artwork \
    look); changing template alone leaves them exactly as they are. One whose artwork "follows template" changes \
    with it. Keep get_design_brief's roles, safe areas and rules: the app name and line in the safe area, no \
    prices, no awards.
    """

    /// What moves in a loop, and what no template can change.
    private static let motionFacts = """
    AppLocalizer animates every header and search loop itself, the same way in every direction: the background \
    light drifts slowly, a scene's moon rises and its stars twinkle, and the phones float gently. No template field \
    changes the motion: not its speed, colors that change over time, an icon that grows or appears, text that comes \
    in after the first frame, or parts that blink. The first frame is the poster, so the name and the line are there \
    from the start. When the note asks for motion like that, change what you can (colors, the scene, the \
    composition, the text, decorations) and say in rationale that AppLocalizer can't animate that yet.
    """
}
