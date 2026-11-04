//
//  AutopilotArtworkConcept.swift
//  AppLocalizer
//

import Foundation

/// One header and search concept, proposed apart from the screenshot
/// directions (`propose_artwork_concept`): the idea Claude Design wrote
/// from the concepts prompt (its name, metaphor, why it fits, how it
/// follows the person's request and how it loops), then its own pages, a
/// still per canvas. With a motion loop, the chosen concept gets a second
/// set of pages, animated (`motion`). The person chooses one at Choose,
/// apart from the screenshot direction.
struct AutopilotArtworkConcept: Codable, Hashable, Sendable, Identifiable {
    /// "A", "B", "C": the id the concept was sent with.
    var id: String
    /// "Moonrise".
    var name: String
    /// The scene template it adapts; nil for one of Claude Design's own.
    var template: AutopilotHeaderTemplate?
    /// Place, viewpoint or wildcard, for one of Claude Design's own.
    var kind: AutopilotConceptKind?
    /// "The crescent from Lumen’s icon rises in a clear evening sky."
    var metaphor: String
    /// "Ties the header to the icon people see right next to it."
    var fitsBecause: String
    /// How it follows what the person asked; nil when they asked nothing.
    var followsTheRequest: String?
    /// The loop's beats: "Dusk", "moonrise", "stars", "dawn".
    var beats: [String] = []
    /// Claude Design recommends it of the three.
    var isRecommended = false
    /// Why, when it's the recommended one.
    var recommendedBecause: String?
    /// The concept as Claude Design wrote it, JSON: what the pages and the
    /// motion prompts get back, and the log keeps.
    var json: String
    /// The still pages, one per canvas, rendered and checked; nil until
    /// they're sent.
    var design: AutopilotArtworkDesign?
    /// Pages render_artwork passed before the concept's own were sent:
    /// the Design row shows them meanwhile.
    var drafts: AutopilotArtworkDesign?
    /// The chosen concept's pages animated into the loop (the motion
    /// prompt); nil until they arrive, and in a still run.
    var motion: AutopilotArtworkDesign?
    /// Where it came from.
    var source: DesignProjectKind
    /// The assistant that sent it.
    var client: String?
    /// Changed after "Ask for changes".
    var isRevised = false
    /// What the last change did, in the designer's words.
    var changeNotes: String?
    var receivedAt: Date

    /// "From the Day to Night template", "Claude Design’s own concept".
    var sourceTitle: String {
        template?.sourceTitle ?? String(localized: "\(source.usesDesignAI ? source.title : DesignProjectKind.claudeDesign.title)’s own concept")
    }

    /// "Dusk → moonrise → stars → dawn"; empty without beats.
    var beatsLine: String { beats.joined(separator: " → ") }

    /// "Loop: Dusk → moonrise → stars → dawn"; nil without beats.
    var loopLine: String? {
        beats.isEmpty ? nil : String(localized: "Loop: \(beatsLine)")
    }

    /// The still pages to show: its own, else the drafts render_artwork
    /// passed.
    var stillDesign: AutopilotArtworkDesign? {
        if let design, !design.isEmpty { return design }
        if let drafts, !drafts.isEmpty { return drafts }
        return nil
    }

    /// The pages the set is made from: the loop's when it has one, else
    /// the stills.
    var madeDesign: AutopilotArtworkDesign? {
        if let motion, !motion.isEmpty { return motion }
        return design
    }

    /// Every canvas among `kinds` has its still page.
    func isDesigned(_ kinds: [AutopilotArtworkKind]) -> Bool {
        guard let design else { return false }
        return design.missing(kinds).isEmpty
    }
}
