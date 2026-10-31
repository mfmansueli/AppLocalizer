//
//  ProposeCaptionsTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_captions`: captions per locale and slot. Each is measured
/// against the current template on iPhone and iPad; the ones that fit go
/// into one proposal in the app's Proposals sheet, the rest are refused
/// with by how much.
struct ProposeCaptionsTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_captions",
        title: "Propose captions",
        description: """
        Proposes screenshot captions, each {locale, slot (from 1), headline, subhead?}. Each item is measured \
        against the current template on iPhone and iPad and refused when it doesn't fit (the reason says by how \
        much, e.g. "needs 3 lines at 72 u; the template allows 2"), when the font can't draw it, or when the \
        locale is unknown. The others are queued together in AppLocalizer's Proposals sheet; nothing changes \
        until the person accepts them, and accepted captions read "Proposed by" you until someone edits them. \
        Keep brand names and the glossary's terms untranslated. During a Screenshot Autopilot run, when \
        next_step asks for write_captions, pass the run's ID as run: the captions are saved right away instead \
        of queued, and the run checks them again.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "items": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "locale": ["type": "string"], "slot": ["type": "integer"], "headline": ["type": "string"], "subhead": ["type": "string"],
                        ],
                        "required": ["locale", "slot", "headline"],
                    ],
                ],
                "reason": MCPToolDefinition.string("Why, in a sentence or two the person reads before accepting."),
                "title": MCPToolDefinition.string("A short title, e.g. Shorter German captions."),
                "run": MCPToolDefinition.string("An Autopilot run's ID, when next_step asked for write_captions."),
            ],
            required: ["appId", "items", "reason"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        if let run = try arguments.optionalString("run"), !run.isEmpty {
            return try await saveForAutopilot(arguments, in: context)
        }
        var draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let reason = try arguments.string("reason")
        let items = try arguments.array("items")
        guard let template = draft.document.template else {
            return .refused(String(localized: "\(draft.app.name) has no screenshot template yet, so captions can’t be measured."), target: draft.target)
        }
        var queued: [CaptionProposalItem] = []
        var results: [JSONValue] = []
        var lines: [MCPToolOutcome.LogLine] = []
        for item in items {
            let code = item["locale"]?.stringValue ?? ""
            let number = item["slot"]?.intValue ?? 0
            let target = "\(draft.app.name) · \(code) · " + String(localized: "slot \(number)")
            switch check(item, template: template, draft: draft) {
            case let .success(proposed):
                queued.append(proposed)
                results.append(["locale": .string(proposed.locale), "slot": .int(number), "status": "queued"])
                lines.append(.init(target: target, outcome: .proposed))
            case let .failure(refusal):
                results.append(["locale": .string(code), "slot": .int(number), "status": "refused", "reason": .string(refusal.message)])
                lines.append(.init(target: target, outcome: .refused, reason: refusal.message))
            }
        }
        var result: [String: JSONValue] = ["items": .array(results)]
        if queued.isEmpty {
            result["status"] = "refused"
        } else {
            let names = Set(queued.map(\.locale)).compactMap(StoreLocaleCatalog.locale(code:)).map(\.name).sorted()
            let proposal = try ScreenshotProposal.captions(
                id: ProposeTemplateTool.newID(), client: context.clientName, receivedAt: .now,
                title: arguments.optionalString("title") ?? String(localized: "Captions for \(names.formatted(.list(type: .and)))"),
                reason: reason, items: queued
            )
            draft.document.proposals.append(proposal)
            try await draft.save()
            result["status"] = queued.count == items.count ? "queued" : "partial"
            result["proposalId"] = .string(proposal.id)
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: lines)
    }

    /// Why an item isn't queued.
    struct Refusal: Error {
        var message: String
    }

    private func check(_ item: JSONValue, template: ScreenshotTemplate, draft: MCPScreenshotsDraft) -> Result<CaptionProposalItem, Refusal> {
        guard let code = item["locale"]?.stringValue, let locale = StoreLocaleCatalog.resolve(code).locale else {
            return .failure(Refusal(message: String(localized: "“\(item["locale"]?.stringValue ?? "")” isn’t an App Store locale.")))
        }
        guard let number = item["slot"]?.intValue, (1...template.slots.count).contains(number) else {
            return .failure(Refusal(message: String(localized: "The template has slots 1 to \(template.slots.count).")))
        }
        let headline = item["headline"]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !headline.isEmpty else { return .failure(Refusal(message: String(localized: "The headline is empty."))) }
        let subhead = item["subhead"]?.stringValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let slot = number - 1
        let current = draft.document.captions.caption(locale: locale.code, slot: slot)
        let caption = ScreenshotCaption(headline: headline, subhead: subhead ?? current?.subhead)
        for display in ScreenshotDisplayType.rendered {
            let layout = draft.layout(template, locale: locale, slot: slot, displayType: display, caption: caption)
            if let problem = layout.headlineFont.problem { return .failure(Refusal(message: problem)) }
            if !layout.headline.fits {
                let suffix = display == .iPhone ? "" : " " + String(localized: "on \(display.title)")
                return .failure(Refusal(message: layout.headline.refusalText + suffix))
            }
        }
        return .success(CaptionProposalItem(locale: locale.code, slot: slot, headline: headline, subhead: subhead))
    }
}
