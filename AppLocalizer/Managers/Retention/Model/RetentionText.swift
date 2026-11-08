//
//  RetentionText.swift
//  AppLocalizer
//

import Foundation

/// One language of a retention message: its header (up to 66 characters)
/// and its message (up to 144). A text over either limit is flagged, never
/// cut.
struct RetentionText: Hashable, Codable, Sendable {
    var header: String
    var body: String
    var origin: RetentionTextOrigin = .written

    static let empty = RetentionText(header: "", body: "")

    var headerCount: Int { RetentionLimits.length(of: header) }
    var bodyCount: Int { RetentionLimits.length(of: body) }

    var isHeaderTooLong: Bool { headerCount > RetentionLimits.headerLength }
    var isBodyTooLong: Bool { bodyCount > RetentionLimits.bodyLength }
    var isTooLong: Bool { isHeaderTooLong || isBodyTooLong }

    /// Nothing written in either field.
    var isEmpty: Bool {
        Self.trimmed(header).isEmpty && Self.trimmed(body).isEmpty
    }

    /// Both fields written; Apple shows a message only with both.
    var isComplete: Bool {
        !Self.trimmed(header).isEmpty && !Self.trimmed(body).isEmpty
    }

    /// The same words, whoever wrote them.
    func hasSameWords(as other: RetentionText?) -> Bool {
        guard let other else { return isEmpty }
        return Self.trimmed(header) == Self.trimmed(other.header) && Self.trimmed(body) == Self.trimmed(other.body)
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
