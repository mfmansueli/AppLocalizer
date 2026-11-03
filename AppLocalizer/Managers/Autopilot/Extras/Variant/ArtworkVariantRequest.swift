//
//  ArtworkVariantRequest.swift
//  AppLocalizer
//

import Foundation

/// Test with Product Page Optimization…: a second header or search image
/// the design source makes with ONE idea changed, by default the app doing
/// its task ("Interface", the current one) against the feeling or result of
/// using it ("Outcome").
struct ArtworkVariantRequest: Codable, Hashable, Sendable {
    /// The placement tested.
    var role: ArtworkTextRole
    /// The image it's drawn on: the header, the search image, or the one
    /// 16:9 image for both.
    var kind: AutopilotArtworkKind
    var controlIdea = ArtworkVariantRequest.interface
    var variantIdea = ArtworkVariantRequest.outcome
    var askedAt: Date

    static let interface = String(localized: "Interface")
    static let outcome = String(localized: "Outcome")

    /// What each default idea means, for the design source.
    static func meaning(of idea: String) -> String {
        switch idea {
        case interface: String(localized: "the app doing the task: its real interface, a focal point on the core action")
        case outcome: String(localized: "the feeling or result of using it: what people get, little or no interface")
        default: idea
        }
    }
}
