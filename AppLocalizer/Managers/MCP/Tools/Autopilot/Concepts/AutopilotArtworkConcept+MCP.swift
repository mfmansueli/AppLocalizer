//
//  AutopilotArtworkConcept+MCP.swift
//  AppLocalizer
//

import Foundation

/// A concept as `propose_artwork_concept` takes it: one item of the
/// concepts prompt's "concepts", as the design AI wrote it, checked like
/// the prompt's answer (one per picked template, or three of different
/// kinds; how it follows the person's request when they asked; no text
/// besides the name and the phrases).
extension AutopilotArtworkConcept {
    static let mcpSchema: JSONValue = [
        "type": "object",
        "description": """
        One item of the concepts prompt's "concepts", as you wrote it: id ("A", "B", "C"), name, kind (place, \
        viewpoint or wildcard, going freely) or template (the template's id, from templates), metaphor, \
        fits_because, follows_the_request, layers, palette, name_style, emblem, phrases {header, search}, \
        search_layout, cycle {type, beats}, poster_moment, risks. Add recommended: true (and recommended_because) \
        on the concept your answer recommends. A JSON string of it works too.
        """,
    ]

    /// The concept in `value` (an object, or its JSON as a string),
    /// refused with what to fix when it isn't one the run takes. Sent
    /// again with an id the run has (its pages after its idea), what's
    /// left out stays as it was.
    @MainActor
    static func mcp(
        _ value: JSONValue?, follows: String?, recommended: Bool?, run: AutopilotRun, client: String, at date: Date
    ) throws -> AutopilotArtworkConcept {
        let object = try object(of: value)
        func text(_ key: String) -> String {
            object[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        let id = text("id")
        if let existing = run.conceptList.first(where: { $0.id == id }) {
            return again(existing, object: object, follows: follows, recommended: recommended, at: date)
        }
        let name = text("name")
        guard !id.isEmpty, !name.isEmpty else {
            throw MCPToolError.invalidArgument(name: "concept", expected: String(localized: "the concept’s id (\"A\", \"B\", \"C\") and name"))
        }
        let metaphor = text("metaphor")
        let fits = text("fits_because")
        guard !metaphor.isEmpty, !fits.isEmpty else {
            throw MCPToolError.invalidArgument(name: "concept", expected: String(localized: "metaphor and fits_because, one sentence each"))
        }
        let extras = run.plan.alsoMakes
        var template: AutopilotHeaderTemplate?
        var kind: AutopilotConceptKind?
        switch extras.artworkStyle {
        case .templates:
            let wanted = text("template").lowercased()
            template = AutopilotHeaderTemplate(rawValue: wanted)
                ?? AutopilotHeaderTemplate.allCases.first { $0.name.localizedCaseInsensitiveCompare(wanted) == .orderedSame }
            guard template != nil else {
                let ids = extras.headerTemplates.map(\.rawValue).formatted(.list(type: .or))
                throw MCPToolError.invalidArgument(name: "concept.template", expected: String(localized: "the template it adapts: \(ids)"))
            }
        case .free:
            kind = AutopilotConceptKind(rawValue: text("kind").lowercased())
            guard kind != nil else {
                throw MCPToolError.invalidArgument(name: "concept.kind", expected: String(localized: "place, viewpoint or wildcard"))
            }
        }
        let request = text("follows_the_request")
        let sent = follows?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let followsTheRequest = [sent, request].first { !$0.isEmpty && !Self.saysNoRequest($0) }
        if !extras.artworkDirection.isEmpty, followsTheRequest == nil {
            throw AutopilotError(ProposeDirectionTool.askedRefusal(extras.artworkDirection))
        }
        try checkPhrases(object["phrases"], run: run)
        let beats = (object["cycle"]?["beats"]?.arrayValue ?? []).compactMap(\.stringValue).map(Self.beat)
        let isRecommended = recommended ?? object["recommended"]?.boolValue ?? false
        let because = text("recommended_because")
        return AutopilotArtworkConcept(
            id: id, name: name, template: template, kind: kind, metaphor: metaphor, fitsBecause: fits,
            followsTheRequest: followsTheRequest, beats: beats.filter { !$0.isEmpty }, isRecommended: isRecommended,
            recommendedBecause: because.isEmpty ? nil : because, json: JSONValue.object(object).jsonString(), design: nil,
            source: run.designKind.usesDesignAI ? run.designKind : .claudeDesign, client: client, receivedAt: date
        )
    }

    /// A concept sent again: what came now laid over what it had.
    private static func again(
        _ existing: AutopilotArtworkConcept, object: [String: JSONValue], follows: String?, recommended: Bool?, at date: Date
    ) -> AutopilotArtworkConcept {
        func text(_ key: String) -> String? {
            let value = object[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return value.isEmpty ? nil : value
        }
        var concept = existing
        concept.name = text("name") ?? existing.name
        concept.metaphor = text("metaphor") ?? existing.metaphor
        concept.fitsBecause = text("fits_because") ?? existing.fitsBecause
        let follows = [follows?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "", text("follows_the_request") ?? ""]
            .first { !$0.isEmpty && !saysNoRequest($0) }
        concept.followsTheRequest = follows ?? existing.followsTheRequest
        let beats = (object["cycle"]?["beats"]?.arrayValue ?? []).compactMap(\.stringValue).map(beat).filter { !$0.isEmpty }
        if !beats.isEmpty { concept.beats = beats }
        concept.isRecommended = recommended ?? object["recommended"]?.boolValue ?? existing.isRecommended
        concept.recommendedBecause = text("recommended_because") ?? existing.recommendedBecause
        // Only an id: the idea stays as it was written.
        if object.keys.contains(where: { $0 != "id" }) {
            var merged = (try? JSONDecoder().decode(JSONValue.self, from: Data(existing.json.utf8)).objectValue) ?? [:]
            merged.merge(object) { $1 }
            concept.json = JSONValue.object(merged).jsonString()
        }
        concept.receivedAt = date
        return concept
    }

    /// The concept's object: sent as one, or as its JSON text.
    private static func object(of value: JSONValue?) throws -> [String: JSONValue] {
        if let object = value?.objectValue { return object }
        if let text = value?.stringValue, let data = text.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(JSONValue.self, from: data), let object = decoded.objectValue
        {
            return object["concepts"]?.arrayValue?.first?.objectValue ?? object
        }
        throw MCPToolError.invalidArgument(name: "concept", expected: String(localized: "the concept as a JSON object"))
    }

    /// "no request", as the prompt says to write it when nothing was asked.
    static func saysNoRequest(_ text: String) -> Bool {
        text.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces)).localizedCaseInsensitiveCompare("no request") == .orderedSame
    }

    /// "0s: dusk over the roofs" → "Dusk over the roofs"; a beat that
    /// says it's the start again is left out.
    static func beat(_ text: String) -> String {
        var beat = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let colon = beat.firstIndex(of: ":"), beat[..<colon].allSatisfy({ $0.isNumber || $0 == "s" || $0 == "." || $0 == " " }) {
            beat = String(beat[beat.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        }
        if beat.lowercased().hasPrefix("same as") { return "" }
        guard let first = beat.first else { return beat }
        return first.uppercased() + beat.dropFirst()
    }

    /// The phrases are only the header's and search's (the prompt allows
    /// no other text), and search has one when the run makes it.
    private static func checkPhrases(_ value: JSONValue?, run _: AutopilotRun) throws {
        guard let value, !value.isNull else { return }
        guard let phrases = value.objectValue else {
            throw MCPToolError.invalidArgument(name: "concept.phrases", expected: String(localized: "{header, search}: 2–5 words each, or null"))
        }
        let allowed: Set = ["header", "search", "wide"]
        if let other = phrases.keys.sorted().first(where: { !allowed.contains($0) }) {
            throw MCPToolError.invalidArgument(
                name: "concept.phrases.\(other)", expected: String(localized: "only the header’s and search’s phrases: no other text goes on the artwork")
            )
        }
    }
}
