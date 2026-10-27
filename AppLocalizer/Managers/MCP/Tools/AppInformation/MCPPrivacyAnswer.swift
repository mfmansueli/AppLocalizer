//
//  MCPPrivacyAnswer.swift
//  AppLocalizer
//

import Foundation

/// One item of `propose_privacy_answers`' `answers`, read and checked: the
/// data type and the suggestion, or why it's refused. Refused items are
/// answered with the reason; the rest of the call still goes through.
struct MCPPrivacyAnswer {
    /// What the assistant sent as the type, for the result.
    var typeText: String
    var type: PrivacyDataType?
    var suggestion: PrivacySuggestion?
    var refusal: String?

    init(_ object: [String: JSONValue], client: String) {
        typeText = object["type"]?.stringValue ?? object["id"]?.stringValue ?? ""
        do {
            let (type, suggestion) = try Self.read(object, typeText: typeText, client: client)
            self.type = type
            self.suggestion = suggestion
        } catch {
            refusal = error.localizedDescription
        }
    }

    private static func read(_ object: [String: JSONValue], typeText: String, client: String) throws -> (PrivacyDataType, PrivacySuggestion) {
        guard let type = PrivacyDataType.matching(typeText) else {
            throw MCPToolError.notFound(String(localized: "Unknown data type “\(typeText)”. Use an id from get_privacy_questionnaire."))
        }
        guard let collected = object["collected"]?.boolValue else {
            throw MCPToolError.invalidArgument(name: "collected", expected: String(localized: "true or false"))
        }
        var purposes: Set<PrivacyPurpose> = []
        for value in object["purposes"]?.arrayValue ?? [] {
            let text = value.stringValue ?? value.jsonString()
            guard let purpose = PrivacyPurpose.matching(text) else {
                let closest = PrivacyPurpose.closest(to: text).rawValue
                throw MCPToolError.notFound(String(localized: "Purpose “\(text)” isn’t one of Apple’s six. Did you mean \(closest)?"))
            }
            purposes.insert(purpose)
        }
        if collected, purposes.isEmpty {
            throw MCPToolError.notFound(String(localized: "Collected data needs at least one purpose. Use the ids from get_privacy_questionnaire."))
        }
        let confidence = object["confidence"]?.stringValue.flatMap { PrivacyConfidence(rawValue: $0.lowercased()) } ?? .medium
        let evidence = (object["evidence"]?.arrayValue ?? []).compactMap(\.objectValue).map(Self.evidence)
        let tracking = collected && object["tracking"]?.boolValue == true
        if tracking, confidence == .high, !evidence.contains(where: \.suggestsTracking) {
            throw MCPToolError.notFound(String(localized: """
            tracking: true at high confidence needs evidence of tracking, such as ATTrackingManager, the advertising \
            identifier or NSPrivacyTracking in a manifest. Add that evidence, or send medium or low confidence.
            """))
        }
        let answer = PrivacyAnswer(
            collected: collected,
            purposes: collected ? purposes : [],
            linked: collected && object["linked"]?.boolValue == true,
            tracking: tracking
        )
        let rationale = object["rationale"]?.stringValue ?? object["why"]?.stringValue ?? ""
        return (type, PrivacySuggestion(answer: answer, confidence: confidence, rationale: rationale, evidence: evidence, client: client))
    }

    /// `{kind, sdk, version, entry, path, line, excerpt}`; an unknown kind
    /// reads as code.
    private static func evidence(_ object: [String: JSONValue]) -> PrivacyEvidence {
        PrivacyEvidence(
            kind: object["kind"]?.stringValue.flatMap(PrivacyEvidenceKind.matching) ?? .code,
            sdk: object["sdk"]?.stringValue,
            version: object["version"]?.stringValue,
            entry: object["entry"]?.stringValue,
            path: object["path"]?.stringValue ?? object["file"]?.stringValue,
            line: object["line"]?.intValue,
            excerpt: object["excerpt"]?.stringValue
        )
    }
}
