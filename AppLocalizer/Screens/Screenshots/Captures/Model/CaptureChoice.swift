//
//  CaptureChoice.swift
//  AppLocalizer
//

import Foundation

/// What to do with files that need you: skip them, or settle what the
/// matcher couldn't.
enum CaptureChoice: Hashable, Sendable, Identifiable {
    case skip
    /// Use this App Store locale for an ambiguous folder.
    case locale(String)
    /// Use a smaller device's capture, scaled up.
    case scaleUp
    /// Add slots to the template up to this 1-based number.
    case addSlot(Int)

    var id: String {
        switch self {
        case .skip: "skip"
        case let .locale(code): "locale.\(code)"
        case .scaleUp: "scaleUp"
        case let .addSlot(number): "addSlot.\(number)"
        }
    }

    /// Whether the files are imported with this choice.
    var imports: Bool { self != .skip }
}
