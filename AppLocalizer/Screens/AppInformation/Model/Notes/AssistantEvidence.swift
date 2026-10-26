//
//  AssistantEvidence.swift
//  AppLocalizer
//

import Foundation

/// Why an assistant answered the way it did: shown in the evidence popover
/// next to its answer.
struct AssistantEvidence: Hashable, Codable, Sendable {
    /// e.g. "Claude Code".
    var client: String
    /// The answer in one line, e.g. "Uses encryption: Yes · exempt: Yes".
    var summary: String
    var why: String
    /// Files, lines and findings, e.g. "Vault/EntryVault.swift:8 — import
    /// CryptoKit".
    var evidence: [String]
    /// What the assistant couldn't see from the code.
    var couldNotSee: String?
}
