//
//  AutopilotCenter+PromptLog.swift
//  AppLocalizer
//

import Foundation

/// Logging the header and search work: each prompt handed out, each answer
/// and each render, so a page can be traced to the prompt and inputs it
/// came from.
extension AutopilotCenter {
    /// The prompts `next_step` handed `provider`, filled with `values`;
    /// `files` are the attached files' hashes.
    func logPrompts(_ prompts: [ArtworkPrompt], values: [String: String], files: [String: String], run: AutopilotRun, provider: String) {
        guard let promptLog else { return }
        for prompt in prompts {
            promptLog.append(ArtworkPromptLogEntry(
                loggedAt: now(), event: .prompt, app: run.appID, run: run.id, provider: provider, designSource: run.designKind.title,
                promptID: prompt.id.rawValue, promptVersion: prompt.version, promptHash: prompt.hash, about: prompt.about,
                inputs: values, files: files.isEmpty ? nil : files
            ))
        }
    }

    /// What `tool` brought back: a concept's JSON and the hash of each page.
    func logAnswer(
        _ tool: String, concept: AutopilotArtworkConcept?, pages: AutopilotArtworkDesign?, checks: [String], run: AutopilotRun, provider: String
    ) {
        guard let promptLog else { return }
        var outputs: [String: String] = ["tool": tool]
        if let concept { outputs["concept"] = concept.json }
        for (kind, html) in pages?.pages ?? [:] { outputs["page.\(kind)"] = ArtworkPrompt.hash(html) }
        promptLog.append(ArtworkPromptLogEntry(
            loggedAt: now(), event: .answer, app: run.appID, run: run.id, provider: provider, designSource: run.designKind.title,
            promptVersion: ArtworkPromptID.version, about: concept?.id, outputs: outputs, checks: checks.isEmpty ? nil : checks
        ))
    }

    /// A page render_artwork rendered on `place` (its canvas, in a
    /// language), and what it found.
    func logRender(
        _ place: (kind: AutopilotArtworkKind, locale: String), html: String, about: String?, checks: [String], run: AutopilotRun, provider: String
    ) {
        guard let promptLog else { return }
        promptLog.append(ArtworkPromptLogEntry(
            loggedAt: now(), event: .render, app: run.appID, run: run.id, provider: provider, designSource: run.designKind.title,
            promptVersion: ArtworkPromptID.version, about: about,
            outputs: ["kind": place.kind.rawValue, "locale": place.locale, "page": ArtworkPrompt.hash(html)], checks: checks
        ))
    }
}
