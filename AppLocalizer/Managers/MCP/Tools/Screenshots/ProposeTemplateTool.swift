//
//  ProposeTemplateTool.swift
//  AppLocalizer
//

import Foundation

/// `propose_template`: a template revision as operations on dotted paths,
/// with the version it's based on. Checked like an edit in the template
/// editor; queued in the app's Proposals sheet, never applied until the
/// person accepts it.
struct ProposeTemplateTool: MCPTool {
    let definition = MCPToolDefinition(
        name: "propose_template",
        title: "Propose template revision",
        description: """
        Proposes a revision of an app's screenshot template as operations on the dotted paths get_template \
        returns, e.g. {op: "replace", path: "caption.headline.size", value: 104}, based on the version you read. \
        Refused for unknown paths, values out of range, and a fallback font that can't draw its script; the \
        reason names each. When queued, it waits in AppLocalizer's Proposals sheet until the person accepts it \
        as the next version, and the result's stress lists how the stress locales (primary, longest, right to \
        left, CJK) fit across every slot with it. Check captions with measure_caption first.
        """,
        inputSchema: MCPToolDefinition.schema(
            [
                "appId": MCPToolDefinition.string("The app's Apple ID, bundle ID, SKU or name, from list_apps."),
                "basedOnVersion": ["type": "integer", "description": "The template version you read with get_template."],
                "ops": [
                    "type": "array",
                    "description": "The changes, each {op: \"replace\", path, value}.",
                    "items": [
                        "type": "object",
                        "properties": ["op": ["type": "string"], "path": ["type": "string"], "value": [:]],
                        "required": ["path", "value"],
                    ],
                ],
                "reason": MCPToolDefinition.string("Why, in a sentence or two the person reads before accepting."),
                "title": MCPToolDefinition.string("A short title, e.g. Smaller headline, hyphenation on."),
            ],
            required: ["appId", "basedOnVersion", "ops", "reason"]
        ),
        proposalKind: .screenshots
    )

    func call(_ arguments: MCPToolArguments, in context: MCPToolContext) async throws -> MCPToolOutcome {
        var draft = try await MCPScreenshotsDraft.load(app: arguments.string("appId"), in: context.workspace)
        let target = draft.target
        let reason = try arguments.string("reason")
        let operations = try TemplateOperation.mcpOperations(from: .array(arguments.array("ops")), argument: "ops")
        guard let basedOn = arguments.values["basedOnVersion"]?.intValue else {
            throw MCPToolError.invalidArgument(name: "basedOnVersion", expected: String(localized: "a version number"))
        }
        _ = try draft.template()
        guard let history = draft.document.history, let base = history.version(basedOn)?.template else {
            let current = draft.document.history?.currentNumber ?? 0
            return .refused(String(localized: "There’s no template v\(basedOn); the current version is v\(current). Read it with get_template."), target: target)
        }
        guard !operations.isEmpty else { return .refused(String(localized: "The proposal has no operations."), target: target) }
        let proposed: ScreenshotTemplate
        switch draft.applier.applying(operations, to: base) {
        case let .success(template): proposed = template
        case let .failure(refusals):
            let details = refusals.items.map { ["path": .string($0.path), "reason": .string($0.reason)] as JSONValue }
            return .refused(refusals.summary, target: target, details: ["refusals": .array(details)])
        }
        let proposal = try ScreenshotProposal.template(
            id: Self.newID(), client: context.clientName, receivedAt: .now,
            title: arguments.optionalString("title") ?? Self.title(for: operations), reason: reason,
            proposal: TemplateProposal(basedOn: basedOn, operations: operations)
        )
        draft.document.proposals.append(proposal)
        try await draft.save()
        var result: [String: JSONValue] = [
            "status": "queued",
            "proposalId": .string(proposal.id),
            "stress": .array(Self.stress(of: proposed, in: draft)),
        ]
        if basedOn < history.currentNumber {
            result["stale"] = .string(String(localized: "Based on v\(basedOn), but the template is now v\(history.currentNumber). The person rebases it before accepting."))
        }
        return MCPToolOutcome(result: .object(result), isError: false, logLines: [.init(target: target, outcome: .proposed)])
    }

    static func newID() -> String {
        "sp-" + UUID().uuidString.prefix(8).lowercased()
    }

    /// "Headline size and 3 more".
    static func title(for operations: [TemplateOperation]) -> String {
        let first = TemplateChange(path: operations[0].path, old: nil, new: operations[0].value).title
        return operations.count == 1 ? first : String(localized: "\(first) and \(operations.count - 1) more")
    }

    /// The stress locales on every slot with `template`: each one's worst
    /// slot.
    static func stress(of template: ScreenshotTemplate, in draft: MCPScreenshotsDraft) -> [JSONValue] {
        let codes = [draft.primary.code] + StressStripPlanner.longestCandidates + [StressStripPlanner.rightToLeftLocale, StressStripPlanner.cjkLocale]
        var seen: Set<String> = []
        return codes.filter { seen.insert($0).inserted }.compactMap(StoreLocaleCatalog.locale(code:)).map { locale in
            let captions = draft.document.captions
            let fits = (0..<template.slots.count).compactMap { slot -> (slot: Int, fit: CaptionFit)? in
                guard let caption = captions.caption(locale: locale.code, slot: slot) ?? captions.caption(locale: draft.primary.code, slot: slot) else {
                    return nil
                }
                return (slot, draft.layout(template, locale: locale, slot: slot, displayType: .iPhone, caption: caption).headline)
            }
            let worst = fits.first { !$0.fit.fits } ?? fits.max { $0.fit.fill < $1.fit.fill }
            var entry: [String: JSONValue] = ["locale": .string(locale.code), "fits": .bool(fits.allSatisfy(\.fit.fits))]
            if let worst {
                entry["label"] = .string(String(localized: "slot \(worst.slot + 1): \(worst.fit.label)"))
            }
            return .object(entry)
        }
    }
}
