//
//  ArtworkPromptFacts+MCP.swift
//  AppLocalizer
//

import Foundation

/// What the prompts are filled from, read where the assistant's tools
/// read it: the App Store page, the look the project scan reported, the
/// design project, the age rating and the primary language's captions.
@MainActor
extension ArtworkPromptFacts {
    static func load(session: MCPAutopilotSession, workspace: MCPWorkspace) async -> ArtworkPromptFacts {
        let app = session.app
        let run = session.run
        var facts = ArtworkPromptFacts()
        facts.profile = await AutopilotAppProfile.load(app: app, locales: run.plan.localeCodes, in: workspace)
        facts.look = workspace.services.storePage.appSupport?.profile(for: app.id)?.look
        facts.designProject = session.center.designProject(for: app.id)
        if let content = try? await workspace.services.appInformation.content(for: app, versionID: nil) {
            let builder = AppInformationChangeBuilder(appID: app.id, ids: content.ids, versionString: content.version?.versionString)
            let values = builder.ageRating(content.ageRating, with: workspace.changes.changes(for: app.id, section: .appInformation))
            facts.ageRating = values.preview.effective.title
        }
        if let document = try? await session.context.services.loadDocument(for: app, primaryLocale: session.context.primaryLocale) {
            for slot in run.plan.screens.indices {
                if let caption = document.captions.caption(locale: run.plan.primaryLocale, slot: slot)?.headline { facts.captions[slot] = caption }
            }
        }
        facts.hasIcon = await AutopilotArtworkPages(context: session.context).icon() != nil
        return facts
    }

    /// The files the prompts come with, by name, as SHA-256: the icon, each
    /// picked capture's id, the person's references.
    static func fileHashes(session: MCPAutopilotSession) async -> [String: String] {
        var files: [String: String] = [:]
        if let icon = await AutopilotArtworkPages(context: session.context).icon() { files["icon"] = ArtworkPrompt.hash(icon) }
        for (slot, screen) in session.run.plan.screens.enumerated() {
            if let capture = session.run.pickedCapture(for: screen.id) { files["capture \(slot + 1)"] = capture.captureID }
        }
        for reference in session.run.plan.alsoMakes.artworkDirection.references {
            let url = session.context.services.referenceURL(reference, for: session.app)
            if let data = try? Data(contentsOf: url) { files[reference.name] = ArtworkPrompt.hash(data) }
        }
        return files
    }
}
