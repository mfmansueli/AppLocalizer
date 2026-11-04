//
//  AutopilotNextStep+MCPVariant.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `design_variant`: the second image a Product Page Optimization test
    /// needs, with one idea changed; the current page when the chosen
    /// direction's artwork is Claude Design's own.
    static func designVariantJSON(_ request: ArtworkVariantRequest, run: AutopilotRun? = nil) -> JSONValue {
        let page = run?.chosenDirection?.artworkDesign?.page(for: request.kind)
        var json: [String: JSONValue] = [
            "action": "design_variant",
            "placement": .string(request.role.rawValue),
            "kind": .string(request.kind.rawValue),
            "pixelSize": .string(request.kind.pixelSize.title),
            "safeArea": ArtworkSafeArea.mcpJSON(for: request.kind),
            "control": [
                "name": .string(request.controlIdea),
                "is": .string(ArtworkVariantRequest.meaning(of: request.controlIdea)),
                "note": "The current image, already live or waiting in Review & Push.",
            ],
            "variant": [
                "name": .string(request.variantIdea),
                "is": .string(ArtworkVariantRequest.meaning(of: request.variantIdea)),
            ],
            "how": .string(variantHow(hasPage: page != nil)),
        ]
        if let page { json["currentPage"] = .string(page) }
        if let phrases = run?.chosenDirection?.artworkDesign?.phrases(for: request.kind), !phrases.isEmpty {
            json["translatedPhrases"] = .array(phrases.map { .string($0) })
        }
        return .object(json)
    }

    /// One idea changed, sent as a page when the current image is one.
    static func variantHow(hasPage: Bool) -> String {
        let send = hasPage
            ? """
            Send it with propose_artwork_variant as html: the whole page, currentPage with the one idea changed, under \
            get_design_brief's artworkDesign rules (try it with render_artwork first); change, and texts only if the \
            words change. The page's phrases (data-al="text") in translatedPhrases are already in every language; \
            for a new or reworded one, send phrases [{phrase, locale, text}] in every other run language.
            """
            : "Send it with propose_artwork_variant (template and/or ops, change, and texts only if the words change)."
        return """
        Design a second image for this placement that changes ONE idea from the current one: the control shows the \
        interface doing the task; the variant shows the outcome or feeling of using the app. Keep the rest (colors, \
        type, the real captures, the placement's role from get_design_brief, the no-price/no-award/no-alpha rules). \
        The text and the focal point stay inside safeArea like the current image's; only the background runs to \
        the edges, and a new idea doesn't move them to the cropped sides or the top. \(send) \
        Apple splits traffic between the current page and this treatment; the person creates the test.
        """
    }
}
