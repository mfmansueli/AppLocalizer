//
//  AutopilotNextStep+MCPVariant.swift
//  AppLocalizer
//

import Foundation

extension AutopilotNextStep {
    /// `design_variant`: the second image a Product Page Optimization test
    /// needs, with one idea changed.
    static func designVariantJSON(_ request: ArtworkVariantRequest) -> JSONValue {
        [
            "action": "design_variant",
            "placement": .string(request.role.rawValue),
            "kind": .string(request.kind.rawValue),
            "pixelSize": .string(request.kind.pixelSize.title),
            "control": [
                "name": .string(request.controlIdea),
                "is": .string(ArtworkVariantRequest.meaning(of: request.controlIdea)),
                "note": "The current image, already live or waiting in Review & Push.",
            ],
            "variant": [
                "name": .string(request.variantIdea),
                "is": .string(ArtworkVariantRequest.meaning(of: request.variantIdea)),
            ],
            "how": """
            Design a second image for this placement that changes ONE idea from the current one: the control shows the \
            interface doing the task; the variant shows the outcome or feeling of using the app. Keep the rest (colors, \
            type, the real captures, the placement's role from get_design_brief, the no-price/no-award/no-alpha rules). \
            Send it with propose_artwork_variant (template and/or ops, change, and texts only if the words change). \
            Apple splits traffic between the current page and this treatment; the person creates the test.
            """,
        ]
    }
}
