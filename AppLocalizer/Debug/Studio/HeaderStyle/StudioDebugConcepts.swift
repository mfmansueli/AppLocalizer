//
//  StudioDebugConcepts.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// Lumen's header concepts, as Claude Design would send them: three from
/// the picked templates and three of its own, each with the pages of
/// `StudioDebugWebArtwork`.
@MainActor
enum StudioDebugConcepts {
    /// Moonrise, Evening Hills and Night Window: from Day to Night,
    /// Layered Landscape and Window View.
    static var fromTemplates: [AutopilotArtworkConcept] {
        [
            concept(
                "A", "Moonrise", template: .night, metaphor: "The crescent from Lumen’s icon rises in a clear evening sky.",
                fits: "Ties the header to the icon people see right next to it.", beats: ["Dusk", "moonrise", "stars", "dawn"],
                pages: StudioDebugWebArtwork.quietIndigo, recommended: true
            ),
            concept(
                "B", "Evening Hills", template: .land, metaphor: "Soft hills at dusk, the view from the desk where you write the day down.",
                fits: "Calm and personal, in the indigo of Lumen’s icon.", beats: ["Dusk", "night", "first light", "dusk"],
                pages: StudioDebugWebArtwork.dawnPanorama
            ),
            concept(
                "C", "Night Window", template: .window, metaphor: "A bedroom window at night: the quiet hour when people write.",
                fits: "Says when Lumen is used, not what it looks like.", beats: ["Blue hour", "night with stars", "dawn", "blue hour"],
                pages: StudioDebugWebArtwork.fullBleed
            ),
        ]
    }

    /// Ink Sky, Lamp-lit Window and Quiet Shore: Claude Design's own.
    static var free: [AutopilotArtworkConcept] {
        [
            concept(
                "A", "Ink Sky", kind: .place,
                metaphor: "The night sky as a page: the moon from the icon is the light you write by, and stars appear like the days you’ve kept.",
                fits: "People write in Lumen at night, and its icon is a moon.", beats: ["Dusk", "stars appear one by one", "moon high", "dawn"],
                pages: StudioDebugWebArtwork.quietIndigo, recommended: true
            ),
            concept(
                "B", "Lamp-lit Window", kind: .viewpoint, metaphor: "Seen from inside: a window at dusk, the room’s warm light on the frame.",
                fits: "Private, indoors and yours: what Lumen promises.", beats: ["Blue hour", "night", "dawn, the lamp glow steady"],
                pages: StudioDebugWebArtwork.fullBleed
            ),
            concept(
                "C", "Quiet Shore", kind: .wildcard, metaphor: "A still shore at dusk with a small boat passing: the day going by.",
                fits: "Looking back over the day, without a word.", beats: ["The boat crosses", "the moon’s path on the water"],
                pages: StudioDebugWebArtwork.dawnPanorama
            ),
        ]
    }

    private static func concept(
        _ id: String, _ name: String, template: AutopilotHeaderTemplate? = nil, kind: AutopilotConceptKind? = nil, metaphor: String,
        fits: String, beats: [String], pages: AutopilotArtworkDesign, recommended: Bool = false
    ) -> AutopilotArtworkConcept {
        AutopilotArtworkConcept(
            id: id, name: name, template: template, kind: kind, metaphor: metaphor, fitsBecause: fits, beats: beats,
            isRecommended: recommended, recommendedBecause: recommended ? "It ties the header to the icon right next to it." : nil,
            json: "{}", design: pages, source: .claudeDesign, client: "Claude Code",
            receivedAt: StudioDebugRuns.date(day: 4, month: 11, hour: 14, minute: 10)
        )
    }
}
#endif
