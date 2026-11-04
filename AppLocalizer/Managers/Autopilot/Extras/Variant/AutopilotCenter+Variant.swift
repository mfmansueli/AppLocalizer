//
//  AutopilotCenter+Variant.swift
//  AppLocalizer
//

import Foundation

/// Test with Product Page Optimization…: the run asks its assistant (the
/// design source) for a second image of the same placement with one idea
/// changed, then renders it in every language like the first and keeps it
/// with the set's extras for the test.
extension AutopilotCenter {
    /// Asks for the variant; the assistant gets it as next_step's
    /// `design_variant`. False when the app has no finished run to ask in.
    @discardableResult
    func requestVariant(appID: StoreApp.ID, role: ArtworkTextRole, kind: AutopilotArtworkKind) -> Bool {
        guard runs[appID]?.stage == .ready else { return false }
        update(appID) { run in
            run.variantRequest = ArtworkVariantRequest(role: role, kind: kind, askedAt: now())
            let client = run.client ?? String(localized: "the assistant")
            run.appendLog(
                String(localized: "Asked \(client) for a second \(role.title.lowercased()) image to test: \(ArtworkVariantRequest.interface) against \(ArtworkVariantRequest.outcome)"),
                kind: .command, at: now()
            )
        }
        return true
    }

    func cancelVariant(appID: StoreApp.ID) {
        update(appID) { $0.variantRequest = nil }
    }

    /// The assistant read what to design (next_step's `design_variant`),
    /// for the sheet's progress.
    func markVariantRead(appID: StoreApp.ID, client: String) {
        update(appID) { run in
            guard run.variantRequest != nil, run.variantRequest?.readAt == nil else { return }
            run.variantRequest?.readAt = now()
            run.appendLog(String(localized: "\(client) read what to change for the test and is designing the variant"), kind: .event, at: now())
        }
    }

    /// The variant the assistant sent: rendered in every language with its
    /// look (and its own texts, when the idea is the words, and its new
    /// page phrases' words, phrase → locale → words), saved with the
    /// extras. Throws when nothing asked for one.
    func receiveVariant(
        appID: StoreApp.ID, look: ScreenshotTemplate, design: AutopilotArtworkDesign? = nil, change: String, texts: [String: String],
        phrases: [String: [String: String]] = [:], client: String, context: AutopilotContext
    ) async throws -> ExtrasArtworkVariant {
        guard let run = runs[appID], let request = run.variantRequest else {
            throw AutopilotError(String(localized: "No variant was asked for. Call next_step to see what AppLocalizer wants."))
        }
        let services = context.services
        var document = try await services.loadDocument(for: context.app, primaryLocale: context.primaryLocale)
        guard document.extras != nil else {
            throw AutopilotError(String(localized: "The set has no header or search artwork to test against."))
        }
        var book = document.artworkTexts ?? ArtworkTextBook()
        let provenance = CaptionProvenance.assistant(client: client, date: now())
        for (locale, headline) in texts {
            book.set(ScreenshotCaption(headline: headline, subhead: nil, provenance: provenance), role: request.role, locale: locale)
        }
        book.setPhrases(phrases, provenance: provenance)
        // The sheet shows it rendering, language by language.
        update(appID) { run in
            run.variantRequest?.receivedAt = now()
            run.variantRequest?.renderedCount = 0
            run.variantRequest?.languageCount = run.plan.localeCodes.count
        }
        let files: [ExtrasArtworkFile]
        do {
            files = try await AutopilotArtworkMaker(context: context, liveTemplate: document.template).make(
                for: run, look: look, design: design, texts: book, kinds: [request.kind]
            ) { count in
                update(appID) { $0.variantRequest?.renderedCount = count }
            }
        } catch {
            // Back to waiting for the assistant, which gets the error.
            update(appID) { run in
                run.variantRequest?.receivedAt = nil
                run.variantRequest?.renderedCount = nil
            }
            throw error
        }
        let variant = ExtrasArtworkVariant(
            role: request.role, kind: request.kind, controlIdea: request.controlIdea, idea: request.variantIdea, change: change,
            template: look, design: design, files: files, client: client, madeAt: now()
        )
        document.extras?.variant = variant
        try await services.saveDocument(document, for: context.app)
        let checks = Self.checks(of: files)
        update(appID) { run in
            run.variantRequest = nil
            run.appendLog(
                String(localized: "\(client) sent the \(request.variantIdea) \(request.role.title.lowercased()) image: \(change). Rendered and checked in \(files.count) languages"),
                kind: .event, at: now()
            )
            if let line = Self.checksLogLine(checks) { run.appendLog(line, kind: checks.contains(where: \.isError) ? .problem : .event, at: now()) }
        }
        return variant
    }
}
