//
//  ArtworkPromptBuilder.swift
//  AppLocalizer
//

import Foundation

/// The run's prompts, filled: the concepts prompt (1A or 1B), each
/// concept's pages (2), the chosen concept's motion (3), and the person's
/// note appended to 2 or 3 (4).
struct ArtworkPromptBuilder {
    let run: AutopilotRun
    let facts: ArtworkPromptFacts
    let appName: String
    /// Reads a prompt's text; the bundle's resource files by default.
    var text: (ArtworkPromptID) -> String = { ArtworkPromptLibrary.text($0) }

    private var values: [String: String] {
        ArtworkPromptValues(run: run, facts: facts, appName: appName).values
    }

    private func filler(_ extra: [String: String] = [:]) -> ArtworkPromptFiller {
        ArtworkPromptFiller(values: values.merging(extra) { $1 }, size: run.plan.alsoMakes.artworkSize, text: text)
    }

    /// 1A when the person goes freely, else 1B with the picked templates.
    /// 1B says its role advice and rules are prompt 1A's, so those (and
    /// 1A's answer) follow it.
    func concepts() -> ArtworkPrompt {
        let filler = filler()
        guard run.plan.alsoMakes.artworkStyle == .templates else {
            return ArtworkPrompt(id: .conceptsFree, text: filler.fill(.conceptsFree))
        }
        let free = filler.fill(.conceptsFree)
        let shared = Self.section(of: free, from: "ROLE ADVICE", to: nil)
        let text = filler.fill(.conceptsTemplates) + (shared.isEmpty ? "" : "\n\nFROM PROMPT 1A (as it says above)\n" + shared)
        return ArtworkPrompt(id: .conceptsTemplates, text: text)
    }

    /// 2: `concept`'s pages.
    func pages(for concept: AutopilotArtworkConcept) -> ArtworkPrompt {
        ArtworkPrompt(id: .pages, text: filler(["concept_json": concept.json]).fill(.pages), about: concept.id)
    }

    /// 3: the chosen concept's pages, animated.
    func motion(for concept: AutopilotArtworkConcept) -> ArtworkPrompt {
        let files = run.plan.artworkKinds.map { "pages.\($0.rawValue)" }.joined(separator: " and ")
        let extra = ["concept_json": concept.json, "page_files": "\(files) below, as you sent them"]
        return ArtworkPrompt(id: .motion, text: filler(extra).fill(.motion), about: concept.id)
    }

    /// 4 appended to `base` (2 at Choose, 3 at Watch): the person's note
    /// for `targets`.
    func change(_ note: String, targets: [AutopilotArtworkConcept], after base: ArtworkPrompt) -> ArtworkPrompt {
        let names = targets.map { "\($0.id) (\($0.name))" }.joined(separator: ", ")
        let change = filler(["user_request": note, "targets": names]).fill(.change)
        return ArtworkPrompt(id: .change, text: base.text + "\n\n" + change, about: targets.map(\.id).joined(separator: ","))
    }

    /// The lines of `text` from the one starting with `start` to the one
    /// before `end` (or the end).
    static func section(of text: String, from start: String, to end: String?) -> String {
        guard let lower = text.range(of: start) else { return "" }
        let rest = text[lower.lowerBound...]
        guard let end, let upper = rest.range(of: end) else { return String(rest) }
        return String(rest[..<upper.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
