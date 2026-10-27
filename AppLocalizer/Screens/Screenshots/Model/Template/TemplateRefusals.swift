//
//  TemplateRefusals.swift
//  AppLocalizer
//

import Foundation

/// Everything wrong with a list of operations. Nothing is applied when
/// any operation is refused.
struct TemplateRefusals: Error, Hashable, Sendable {
    var items: [TemplateRefusal]

    /// One line per refusal, for a tool result or a log entry.
    var summary: String {
        items.map { "\($0.path): \($0.reason)" }.joined(separator: "\n")
    }
}
