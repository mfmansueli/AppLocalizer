//
//  RenderCheck.swift
//  AppLocalizer
//

import Foundation

/// One check on a render (README §5). Failed checks block the push and
/// keep the render out of Review & Push; warnings don't; pending checks
/// wait for a caption or a capture and show the fallback meanwhile.
struct RenderCheck: Hashable, Sendable, Identifiable {
    var kind: Kind
    var status: Status
    /// The full sentence for the viewer, e.g. "Headline overflows: 1 line
    /// too many at 80 u".
    var text: String
    /// The badge reason: "Overflow", "Missing glyphs", "Wrong size".
    var shortReason: String?

    var id: Kind { kind }

    var blocksPush: Bool { status == .failed }

    enum Kind: String, Hashable, Sendable, CaseIterable {
        case sizeAndFormat
        case glyphs
        case fit
        case captureSize
        case interfaceLocalized
        case captionPresent
        case capturePresent
    }

    enum Status: String, Hashable, Sendable {
        case passed
        case failed
        case warning
        case pending
    }
}
