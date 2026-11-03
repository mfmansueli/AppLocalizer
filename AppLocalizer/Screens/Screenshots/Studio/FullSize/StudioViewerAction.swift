//
//  StudioViewerAction.swift
//  AppLocalizer
//

import Foundation

/// The button in the viewer's top bar: Use This Capture on one of a
/// screen's attempts at Pick, Show iPhone Area on the header artwork.
enum StudioViewerAction: Hashable {
    /// Uses this attempt for the screen; `isUsed` when it already is.
    case useCapture(captureID: String, screenID: String, screenName: String, isUsed: Bool)
    /// Shows or hides the part of the header iPhone shows.
    case headerGuide

    /// "Use This Capture", "✓ Used for Week", "Show iPhone Area".
    func title(showsGuide: Bool) -> String {
        switch self {
        case let .useCapture(_, _, name, isUsed) where isUsed: String(localized: "✓ Used for \(name)")
        case .useCapture: String(localized: "Use This Capture")
        case .headerGuide where showsGuide: String(localized: "Hide iPhone Area")
        case .headerGuide: String(localized: "Show iPhone Area")
        }
    }

    var isEnabled: Bool {
        if case let .useCapture(_, _, _, isUsed) = self { return !isUsed }
        return true
    }

    var isProminent: Bool {
        if case let .useCapture(_, _, _, isUsed) = self { return !isUsed }
        return false
    }
}
