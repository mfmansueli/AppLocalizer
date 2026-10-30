//
//  SuggestionEvidence.swift
//  AppLocalizer
//

import Foundation

/// What an assistant based a suggestion on, e.g. `git` `v1.3..4f2c91a` or
/// `code` `Lumen/Debug/DebugMenu.swift:18`.
struct SuggestionEvidence: Hashable, Codable, Sendable {
    var kind: String
    var ref: String
}
