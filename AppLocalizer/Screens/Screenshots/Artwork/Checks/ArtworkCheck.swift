//
//  ArtworkCheck.swift
//  AppLocalizer
//

import Foundation

/// One finding on a rendered header or search image in one language, shown
/// like a screenshot check: a pill (`shortReason`) and a line (`text`).
/// Errors block pushing that image; warnings don't.
struct ArtworkCheck: Codable, Hashable, Sendable {
    var kind: ArtworkCheckKind
    var severity: ArtworkCheckSeverity
    /// "German header: ‘−50%’ — discounts aren’t allowed here."
    var text: String
    var shortReason: String

    init(kind: ArtworkCheckKind, severity: ArtworkCheckSeverity? = nil, text: String, shortReason: String? = nil) {
        self.kind = kind
        self.severity = severity ?? (kind.isApplesRule ? .error : .warning)
        self.text = text
        self.shortReason = shortReason ?? kind.shortReason
    }

    var isError: Bool { severity == .error }
}
