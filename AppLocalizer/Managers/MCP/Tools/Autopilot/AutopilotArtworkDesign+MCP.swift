//
//  AutopilotArtworkDesign+MCP.swift
//  AppLocalizer
//

import Foundation

/// The header and search pages over MCP: what get_design_brief tells
/// Claude Design about making them, and the `artworkDesign` argument of
/// propose_direction and revise_direction.
extension AutopilotArtworkDesign {
    /// The `artworkDesign` argument's schema.
    static let mcpSchema: JSONValue = [
        "type": "object",
        "description": """
        The header and search images, designed by you: one self-contained HTML page per canvas the run makes \
        (header, search, or wide for the one 16:9 image), as get_design_brief's artworkDesign describes. \
        In revise_direction, send only the pages that change.
        """,
        "properties": [
            "header": ["type": "string", "description": "The product page header's page (21:9)."],
            "search": ["type": "string", "description": "The search results image's page (3:2)."],
            "wide": ["type": "string", "description": "The one 16:9 image's page, both header and search."],
        ],
    ]

    /// The pages in a tool's `artworkDesign`; nil when it isn't sent.
    /// Refused for a canvas the run doesn't make, or one too heavy.
    static func mcpPages(_ arguments: MCPToolArguments, kinds: [AutopilotArtworkKind]) throws -> AutopilotArtworkDesign? {
        guard let object = try arguments.optionalObject("artworkDesign") else { return nil }
        var design = AutopilotArtworkDesign()
        for (key, value) in object {
            guard let kind = AutopilotArtworkKind(rawValue: key), kinds.contains(kind) else {
                let names = kinds.map(\.rawValue).formatted(.list(type: .or))
                throw MCPToolError.invalidArgument(name: "artworkDesign.\(key)", expected: String(localized: "one of the run’s canvases: \(names)"))
            }
            guard let html = value.stringValue ?? value["html"]?.stringValue, !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw MCPToolError.invalidArgument(name: "artworkDesign.\(key)", expected: String(localized: "the page’s HTML, as a string"))
            }
            guard html.utf8.count <= maximumBytes else { throw MCPToolError.invalidArgument(name: "artworkDesign.\(key)", expected: ArtworkWebError.tooLarge(html.utf8.count).localizedDescription) }
            design.setPage(html, for: kind)
        }
        return design.isEmpty ? nil : design
    }

    /// get_design_brief's `artworkDesign`: what the person asked for first,
    /// then everything AppLocalizer does with the pages, so Claude Design
    /// makes every decision with it in mind.
    static func mcpContract(for run: AutopilotRun, referenceURL: ((AutopilotArtworkReference) -> URL)? = nil) -> JSONValue {
        let plan = run.plan
        let extras = plan.alsoMakes
        let rightToLeft = plan.localeCodes.filter { StoreLocaleCatalog.locale(code: $0)?.isRTL == true }
        let asked = extras.artworkDirection
        var json: [String: JSONValue] = [
            "youDesignIt": .string("""
            The header and search images are yours, completely: the idea, composition, scene or illustration, typography, \
            color and motion. AppLocalizer draws nothing of its own on them. Send each canvas as one HTML page with \
            propose_direction's artworkDesign; AppLocalizer renders it in every language at Apple's exact size, fills in \
            what you mark, checks it, and makes the motion loop from your CSS. Make the three directions' images truly \
            different ideas, not one layout recolored\(asked.isEmpty ? "" : ", each its own take on what the person asked (askedByThePerson)").
            """),
            "pages": .array(plan.artworkKinds.map { kind in
                [
                    "key": .string(kind.rawValue), "pixelSize": .string(kind.pixelSize.title),
                    "css": .string("html, body { margin: 0; width: \(kind.pixelSize.width)px; height: \(kind.pixelSize.height)px; overflow: hidden; }"),
                ]
            }),
            "page": """
            One HTML document per canvas. html and body are exactly the canvas's pixelSize in CSS px (1 CSS px is 1 pixel of \
            the image), overflow hidden, with an opaque background of your own (Apple takes no transparency). Everything \
            inline: <style>, inline SVG, data: URIs, CSS gradients, filters, masks, blend modes. No scripts (they never \
            run), no external URLs or web fonts (the network is blocked), no iframes. At most 2 MB.
            """,
            "fillIns": mcpFillIns,
            "languages": .string("""
            AppLocalizer renders every language: \(plan.localeCodes.joined(separator: ", ")). Each page gets lang and dir on \
            <html>. German, Finnish or Russian run up to 40% longer than English and Chinese, Japanese or Korean much \
            shorter: leave the headline room or let it fit.
            """),
            "fonts": .string("""
            System fonts by CSS keyword: system-ui (SF Pro), ui-serif (New York), ui-rounded (SF Pro Rounded), \
            ui-monospace (SF Mono). AppLocalizer's own, by family name: \(BundledFonts.names.joined(separator: ", ")). \
            Any family installed on this Mac by name. For scripts a font lacks (Chinese, Japanese, Korean, Thai, \
            Arabic, Hebrew, Hindi…) the system picks one that draws them.
            """),
            "rendering": """
            How each image is made: AppLocalizer loads your page at the canvas size, sets lang and dir, fills in the \
            data-al elements for the language, waits for its images and fonts, fits the text, pauses all animation at \
            the start (the poster), draws it and flattens it to an opaque PNG. Call render_artwork with a page to see \
            exactly that, with its checks, in any language before proposing.
            """,
            "checks": """
            Then every language is checked: the text and the focal point inside the safe area; text contrast of 3:1 or \
            more against what's behind it; nothing Apple forbids in the text, read from the image with Vision (prices, \
            percentages, URLs, ©, awards, Apple's recognitions, other platforms); edges that don't melt into the App \
            Store page in Light or Dark Mode; the header sharing the first screenshot's colors and typeface; text that \
            doesn't fit; and for a loop, no jump and text that stays still.
            """,
        ]
        if !rightToLeft.isEmpty {
            json["rightToLeft"] = .string("""
            \(rightToLeft.joined(separator: ", ")) get dir="rtl": lay the page out with logical CSS (inset-inline-start, \
            margin-inline, text-align: start, flex or grid) so it mirrors, or keep it as it is where mirroring would be \
            wrong. Captures never mirror.
            """)
        }
        json["motion"] = .string(mcpMotion(makesMotion: extras.makesMotion))
        if !asked.isEmpty { json["askedByThePerson"] = mcpAsked(asked, referenceURL: referenceURL) }
        if run.usesConcepts { conceptContract(&json, run: run) }
        return .object(json)
    }

    /// A run with header concepts: the pages come with each concept
    /// (`propose_artwork_concept`, the prompts next_step hands out), their
    /// words are the name and their phrases, and motion comes after the
    /// person chose, from the motion prompt.
    static func conceptContract(_ json: inout [String: JSONValue], run: AutopilotRun) {
        let extras = run.plan.alsoMakes
        json["youDesignIt"] = .string("""
        The header and search images are yours, completely, and come as concepts apart from the screenshot directions: \
        follow the prompts next_step hands you, and send each concept and its pages with propose_artwork_concept \
        (never in propose_direction). AppLocalizer renders each page in every language at Apple's exact size, fills in \
        what you mark and checks it.
        """)
        json["style"] = .string(extras.artworkStyle.rawValue)
        if extras.artworkStyle == .templates { json["templates"] = .array(extras.headerTemplates.map { .string($0.rawValue) }) }
        json["show"] = .string(extras.artworkShows.rawValue)
        json["motionHow"] = json["motion"]
        json["motion"] = .string(extras.makesMotion ? "loop" : "still")
        if extras.makesMotion {
            json["motionHow"] = .string("""
            Make the stills first, with no animation. Once the person chose a header, next_step says animate_header: the \
            motion prompt turns that concept's pages into a \(AutopilotArtworkMotion.loopSeconds)-second loop.
            """)
        }
        json["marks"] = .array(["appName", "text", "capture", "icon"].map { .string($0) })
        var fillIns = mcpFillIns.objectValue ?? [:]
        fillIns["headline"] = nil
        fillIns["text"] = """
        data-al="text" with data-phrase="1", data-phrase="2"…: the concept's phrases, written once in the primary \
        language. AppLocalizer translates each at Localize like the captions and fits it.
        """
        json["fillIns"] = .object(fillIns)
    }

    /// The plan's "Expected result", as the first thing the pages answer:
    /// it comes before AppLocalizer's own advice.
    static func mcpAsked(_ asked: AutopilotArtworkDirection, referenceURL: ((AutopilotArtworkReference) -> URL)? = nil) -> JSONValue {
        var json: [String: JSONValue] = [
            "priority": """
            What the person asked these images to be, in their words. It comes first: every direction's header and \
            search show it, plainly enough that they see their request in it at a glance, each direction its own take. \
            It outranks AppLocalizer's advice in extras (roles, one short line, a device, the starter's look); only \
            Apple's rules, an opaque background, the safe area and text that reads come before it. When they ask for \
            words on the image (phrases, quotes, a slogan, a list), write them yourself with data-al="text", once, in \
            the primary language; AppLocalizer translates them. propose_direction's followsTheRequest says how each \
            direction answers it.
            """,
        ]
        if !asked.trimmedText.isEmpty { json["expectedResult"] = .string(asked.trimmedText) }
        if !asked.references.isEmpty {
            json["references"] = .array(asked.references.map { reference in
                var item: [String: JSONValue] = ["name": .string(reference.name), "kind": .string(reference.isVideo ? "video" : "image")]
                if let url = referenceURL?(reference) { item["path"] = .string(url.path) }
                return .object(item)
            })
            json["referencesSay"] = "Images and videos they like: take the feel from them (open each path); don't copy them."
        }
        return .object(json)
    }

    /// What a page's `data-al` elements get filled in with.
    static let mcpFillIns: JSONValue = [
        "headline": """
        data-al="headline" on a block element (h1, div, p): AppLocalizer writes the placement's own text into it, \
        in each language (search: its 3–5 word headline; header: its short line, often empty, so style :empty). \
        Give it a box, a width and a height or max-height, and add data-al-fit to shrink the text until it fits \
        (down to 40% of its size), data-al-lines="2" to cap its lines. Plain text only: markup inside is replaced.
        """,
        "appName": """
        data-al="appName": AppLocalizer writes the app's name as each language's App Store page has it \
        (aboutTheApp's languages[].name), so leave it room to run longer than the primary language's.
        """,
        "text": """
        data-al="text" on a block element: your own words beyond the headline (phrases, quotes, labels, a list item), \
        one element each, written once as plain text in the primary language: <p data-al="text" data-al-fit>Small \
        steps count.</p>. AppLocalizer translates each phrase at Localize like the captions, writes each language's \
        words into it, fits it like the headline (data-al-fit, data-al-lines) and checks its contrast and safe area; \
        the person reviews them in Captions. Give each room to run longer in other languages, and show every phrase \
        at 0 s, the still image and the loop's poster, not only once the motion brings it in. Words written anywhere else on \
        the page read the same in every language, so propose_direction refuses them when the run has more than one \
        language (digits and symbols are fine).
        """,
        "icon": "<img data-al=\"icon\">: the app's own icon, square; round its corners yourself (about 22.5%).",
        "capture": """
        <img data-al="capture" data-slot="N">: the language's picked capture of screen N (from 1, as in \
        get_design_brief's picks), the app's real interface; never mirrored or drawn by you. Frame it in a \
        device you draw with CSS, float it bare, crop it, or leave it out. Any element can be data-al="capture" \
        to take it as its background image instead.
        """,
    ]

    /// How the pages move: CSS stepped frame by frame into the loop, or a
    /// still.
    static func mcpMotion(makesMotion: Bool) -> String {
        makesMotion
            ? """
            Each image is also a \(AutopilotArtworkMotion.loopSeconds)-second silent loop at \
            \(AutopilotArtworkMotion.loopFramesPerSecond) fps whose first frame is the poster: AppLocalizer pauses your \
            CSS animations (and SVG <animate>) at each frame's moment and draws it. So animate with CSS @keyframes or \
            transitions, infinite, each cycle dividing \(AutopilotArtworkMotion.loopSeconds) s (20, 10, 5, 4 s…) so the \
            last frame meets the first. Slow and ambient: light, sky, weather, particles, a gentle float or turn of the \
            device. The headline, name and icon stay still and readable from the first frame (no fade-ins). Motion \
            driven by scripts isn't possible.
            """
            : "These are stills: only the start of any animation is drawn."
    }
}
