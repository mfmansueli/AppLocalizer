//
//  AutopilotLoopRevision.swift
//  AppLocalizer
//

import Foundation

/// One version of the header loop from the design source: what the
/// person asked and what changed.
struct AutopilotLoopRevision: Codable, Hashable, Sendable {
    /// 2, 3…
    var version: Int
    /// "Slower movement, warmer light": the designer's change notes.
    var changes: String
    /// What the person asked.
    var note: String
    var client: String
    var madeAt: Date
}
