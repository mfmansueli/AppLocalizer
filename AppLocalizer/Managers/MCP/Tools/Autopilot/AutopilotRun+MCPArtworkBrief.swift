//
//  AutopilotRun+MCPArtworkBrief.swift
//  AppLocalizer
//

import Foundation

/// `get_design_brief`'s header and search artwork: the canvases, and what
/// each placement is for, so the design source gives them different jobs.
extension AutopilotRun {
    /// `referenceURL` says where each reference the person attached is.
    func mcpArtworkBrief(referenceURL: ((AutopilotArtworkReference) -> URL)? = nil) -> [String: JSONValue] {
        let wide = plan.alsoMakes.artworkSize == .wide
        let headerInsets = ArtworkSafeArea.percentInsets(for: .header)
        let wideInsets = ArtworkSafeArea.percentInsets(for: .wide)
        var json: [String: JSONValue] = [
            "header": .string(wide ? "16:9" : "21:9"),
            "search": .string(wide ? "16:9" : "3:2"),
            "canvases": .array(plan.artworkKinds.map { kind in
                [
                    "kind": .string(kind.rawValue),
                    "pixelSize": .string(kind.pixelSize.title),
                    "text": .string(ArtworkTextRole.role(for: kind).rawValue),
                    "placements": .array(kind.placementTypes.map(JSONValue.string)),
                    "safeArea": ArtworkSafeArea.mcpJSON(for: kind),
                ]
            }),
            "safeArea": .string(ArtworkSafeArea.mcpRule),
            "roles": [
                "search": """
                People comparing apps for what they searched, not committed yet, on a small card that takes the place of up \
                to 3 screenshots (Apple: "state the obvious", "showcase the firsthand experience"). Show the real \
                interface doing the core task: one focal point, centered, readable at small size. Its text is a 3–5 word \
                headline that answers the search, written per language from the keywords and subtitle.
                """,
                "header": .string("""
                People who already tapped into the app, seeing it first (Apple: it "sets the tone", "focus on a single, \
                clear idea", design for a first-time visitor). Brand first: the app name and one short line (at most \
                about 3 words, none by default), centered, with no phone; on iPhone only the middle shows (\(headerInsets.side)% is \
                cut on each side) and the status bar, Back and Share sit over the top \(headerInsets.top)%, so the name and line \
                sit in the safe area's middle, never at the top. Visually continuous with the app icon and the first \
                screenshot below it, which must deliver on that promise.
                """),
            ],
            "aboutTheApp": .string(Self.aboutTheAppRule),
            "captures": plan.alsoMakes.artworkShows.needsCaptures
                ? "The phones and screens in both are the real picked captures, never drawn interfaces."
                : "No app screens and no device: a scene in the brand's style, with the name and the headline.",
            "rules": """
            No prices or currency, discounts or percentages, URLs, ©, awards or claims that can't be verified, Apple \
            recognitions (Editor's Choice, App of the Day, Game of the Day, Apple Design Award) or other platforms and \
            stores; no transparency. Everything must suit a 4+ age rating. AppLocalizer checks each render in every \
            language before Review & Push.
            """,
            "video": plan.alsoMakes.makesMotion
                ? """
                Each is a 20-second silent loop (.mov, 30 fps): slow, ambient movement only, the name and headline still. \
                AppLocalizer animates the direction's artwork into the loop, so its first frame (the poster) must work as \
                a still and its last frame matches the first.
                """
                : """
                If a header or search becomes a video later: the search video is always muted, so its first second shows \
                the core action; the header video is calm and loops without a visible jump. This plan makes images only.
                """,
            "shownOn": "iOS 27 and iPadOS 27 and later; earlier versions show the screenshots, which stay required.",
        ]
        let extras = plan.alsoMakes
        json["art_motion"] = .string(extras.makesMotion ? "loop" : "still")
        json["art_show"] = .string(extras.artworkShows.rawValue)
        let direction = extras.artworkDirection
        if !direction.isEmpty {
            json["art_direction"] = [
                "text": .string(direction.trimmedText),
                "references": .array(direction.references.map { reference in
                    var item: [String: JSONValue] = ["name": .string(reference.name), "kind": .string(reference.isVideo ? "video" : "image")]
                    if let url = referenceURL?(reference) { item["path"] = .string(url.path) }
                    return .object(item)
                }),
            ]
        }
        json["art_brief"] = .array(AutopilotArtworkBrief(extras).rows.map { ["rule": .string($0.title), "says": .string($0.text)] })
        if wide {
            json["bothCrops"] = .string("""
            One 16:9 image is both the header and the search image, so it must work in both crops: the focal point and \
            the text in the center safe area (the header cuts \(wideInsets.side)% off each side and the top \(wideInsets.top)%; \
            search shows it whole).
            """)
        }
        return json
    }

    /// The artwork is about this app.
    static let aboutTheAppRule = """
    Both are about this app, not its category: their idea, scene and colors come from aboutTheApp (its subtitle, \
    description, keywords and icon colors) and the captures; the search headline names its core task in its own words.
    """
}
