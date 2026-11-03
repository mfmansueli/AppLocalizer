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
            // A placement's own text: the search headline or the header line.
            if let value = item["placement"]?.stringValue {
                guard let role = ArtworkTextRole(rawValue: value), let code = item["locale"]?.stringValue,
                      let locale = StoreLocaleCatalog.resolve(code).locale, session.run.plan.localeCodes.contains(locale.code)
                else {
                    return .refused(String(localized: "A placement item needs a locale of the plan and placement search or header."), target: session.target)
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
        lines += texts.map { MCPToolOutcome.LogLine(target: "\(session.app.name) · \($0.locale) · \($0.role.title)", outcome: .proposed) }
        return MCPToolOutcome(result: result, isError: false, logLines: lines)
    }
}
