//
//  TemplateProposal.swift
//  AppLocalizer
//

import Foundation

/// A template revision as an assistant sends it:
/// `{ basedOn: 4, ops: [{ op: "replace", path: "caption.headline.size", value: 104 }] }`.
/// Accepting applies the operations through `TemplateOperationApplier` and
/// saves the next version, tagged with the assistant.
struct TemplateProposal: Codable, Hashable, Sendable {
    var basedOn: Int
    var operations: [TemplateOperation]
    /// The version it was based on before a rebase, for "rebased from v3".
    var rebasedFrom: Int?

    enum CodingKeys: String, CodingKey {
        case basedOn
        case operations = "ops"
        case rebasedFrom
    }
}
