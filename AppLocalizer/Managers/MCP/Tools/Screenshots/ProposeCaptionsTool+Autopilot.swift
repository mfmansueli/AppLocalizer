//
//  ProposeCaptionsTool+Autopilot.swift
//  AppLocalizer
//

import Foundation

extension ProposeCaptionsTool {
    /// `propose_captions` with an Autopilot run: the captions the run asked
    /// for are saved at once (the run's Localize and check measures them
    /// again), not queued.
    func saveForAutopilot(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        let session = try await MCPAutopilotSession.load(arguments, in: context)
        var updates: [AutopilotCaptionUpdate] = []
        var texts: [AutopilotArtworkTextUpdate] = []
        for item in try arguments.array("items") {
            // One of the pages' phrases in a language.
            if item["placement"]?.stringValue == "text" {
                switch Self.phraseUpdate(item, run: session.run) {
                case let .success(update): texts.append(update)
                case let .failure(refusal): return .refused(refusal.message, target: session.target)
                }
                continue
            }
            // A placement's own text: the search headline or the header line.
            if let value = item["placement"]?.stringValue {
                guard let role = ArtworkTextRole(rawValue: value), let code = item["locale"]?.stringValue,
                      let locale = StoreLocaleCatalog.resolve(code).locale, session.run.plan.localeCodes.contains(locale.code)
                else {
                    let refusal = String(localized: "A placement item needs a locale of the plan and placement search, header or text.")
                    return .refused(refusal, target: session.target)
                }
                let headline = item["headline"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !headline.isEmpty || role.isOptional else {
                    return .refused(String(localized: "Every language needs a search headline."), target: session.target)
                }
                texts.append(AutopilotArtworkTextUpdate(locale: locale.code, role: role, headline: headline))
                continue
            }
            guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale,
                  session.run.plan.localeCodes.contains(locale.code),
                  let number = item["slot"]?.intValue, session.run.plan.screens.indices.contains(number - 1),
                  let headline = item["headline"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !headline.isEmpty
            else {
                return .refused(String(localized: "Each item needs a locale of the plan, a slot from 1 to \(session.run.plan.screens.count) and a headline."), target: session.target)
            }
            updates.append(AutopilotCaptionUpdate(
                locale: locale.code, slot: number - 1, headline: headline,
                subhead: item["subhead"]?.stringValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            ))
        }
        do {
            let center = session.center
            try await center.applyArtworkTexts(texts, client: context.clientName, appID: session.app.id, context: session.context, recheck: updates.isEmpty)
            if !updates.isEmpty {
                try await center.applyCaptions(updates, client: context.clientName, appID: session.app.id, context: session.context)
            }
        } catch {
            return .refused(error.localizedDescription, target: session.target)
        }
        let run = session.center.run(for: session.app.id)
        let left = (run?.overflows.count ?? 0) + (run?.artworkTextNeeds?.count ?? 0)
        let result: JSONValue = ["status": "saved", "saved": .int(updates.count + texts.count), "stillNotFitting": .int(left)]
        var lines = updates.map { MCPToolOutcome.LogLine(target: "\(session.app.name) · \($0.locale) · " + String(localized: "slot \($0.slot + 1)"), outcome: .proposed) }
        lines += texts.map { text in
            let place = text.phrase.map { "“\(ArtworkCheckGeometry.snippet($0))”" } ?? text.role.title
            return MCPToolOutcome.LogLine(target: "\(session.app.name) · \(text.locale) · \(place)", outcome: .proposed)
        }
        return MCPToolOutcome(result: result, isError: false, logLines: lines)
    }

    /// A phrase item {locale, placement: "text", phrase, headline}: one of
    /// the chosen direction's phrases (its words in the primary language,
    /// as next_step gave them) in a language of the plan; in the primary
    /// language, shorter words for one that doesn't fit.
    static func phraseUpdate(_ item: JSONValue, run: AutopilotRun) -> Result<AutopilotArtworkTextUpdate, ProposeCaptionsPhraseRefusal> {
        guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale,
              run.plan.localeCodes.contains(locale.code)
        else {
            return .failure(ProposeCaptionsPhraseRefusal(String(localized: "A text item needs a locale of the plan.")))
        }
        let design = run.madeArtworkDesign
        let known = design?.allPhrases(in: run.plan.artworkKinds) ?? []
        let phrase = ArtworkTextBook.phraseKey(item["phrase"]?.stringValue ?? "")
        guard !phrase.isEmpty, known.isEmpty || known.contains(phrase) else {
            let list = known.map { "“\($0)”" }.joined(separator: ", ")
            return .failure(ProposeCaptionsPhraseRefusal(String(localized: """
            A text item’s phrase must be one of the pages’ phrases, exactly as next_step gave it: \(list).
            """)))
        }
        let headline = ArtworkTextBook.phraseKey(item["headline"]?.stringValue ?? "")
        guard !headline.isEmpty else {
            return .failure(ProposeCaptionsPhraseRefusal(String(localized: "A text item needs the phrase’s words in \(locale.code) as headline.")))
        }
        let kind = design?.kind(writing: phrase) ?? run.plan.artworkKinds.first ?? .header
        return .success(AutopilotArtworkTextUpdate(locale: locale.code, role: ArtworkTextRole.role(for: kind), headline: headline, phrase: phrase))
    }
}
