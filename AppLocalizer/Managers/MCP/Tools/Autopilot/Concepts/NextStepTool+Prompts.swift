//
//  NextStepTool+Prompts.swift
//  AppLocalizer
//

import Foundation

/// The prompts `next_step` hands the assistant in a run with header
/// concepts: the concepts prompt, each concept's pages prompt, the motion
/// prompt for the chosen header, and the person's note appended to the
/// one it's for. Each is logged with its inputs.
extension NextStepTool {
    /// The prompts for `step`, or none when it needs none.
    static func prompts(for step: AutopilotNextStep, session: MCPAutopilotSession, context: MCPToolContext) async -> [ArtworkPrompt] {
        let workspace = context.workspace
        let run = session.run
        guard run.usesConcepts else { return [] }
        switch step {
        case .design, .revise, .animateHeader, .reviseLoop: break
        default: return []
        }
        let facts = await ArtworkPromptFacts.load(session: session, workspace: workspace)
        let builder = ArtworkPromptBuilder(run: run, facts: facts, appName: session.app.name)
        let prompts = prompts(for: step, run: run, builder: builder)
        guard !prompts.isEmpty else { return [] }
        let values = ArtworkPromptValues(run: run, facts: facts, appName: session.app.name).values
        let files = await ArtworkPromptFacts.fileHashes(session: session)
        session.center.logPrompts(prompts, values: values, files: files, run: run, provider: context.clientName)
        return prompts
    }

    /// Which prompts `step` takes, filled by `builder`.
    static func prompts(for step: AutopilotNextStep, run: AutopilotRun, builder: ArtworkPromptBuilder) -> [ArtworkPrompt] {
        switch step {
        case .design:
            var prompts: [ArtworkPrompt] = []
            if run.conceptList.count < run.expectedConcepts { prompts.append(builder.concepts()) }
            for concept in run.conceptList where !concept.isDesigned(run.plan.artworkKinds) {
                prompts.append(builder.pages(for: concept))
            }
            return prompts
        case let .revise(note):
            let revised = Set(run.revision?.revisedIDs ?? [])
            let targets = (run.revision?.askedConcepts ?? []).compactMap { run.concept($0) }
            return targets.filter { !revised.contains($0.id) }.map { concept in
                builder.change(note, targets: targets, after: builder.pages(for: concept))
            }
        case let .animateHeader(conceptID):
            return run.concept(conceptID).map { [builder.motion(for: $0)] } ?? []
        case let .reviseLoop(note):
            guard let concept = run.chosenConcept else { return [] }
            return [builder.change(note, targets: [concept], after: builder.motion(for: concept))]
        default:
            return []
        }
    }
}
