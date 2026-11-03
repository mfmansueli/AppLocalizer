//
//  AutopilotArtworkShow.swift
//  AppLocalizer
//

import Foundation

/// What the search results artwork shows beside its headline. The header
/// never shows a device; one 16:9 image follows the same choice.
enum AutopilotArtworkShow: String, Codable, CaseIterable, Hashable, Sendable {
    /// One real screen from the captures, in a phone.
    case phone
    /// The same real screen, cropped, rounded and floating, with no phone.
    case ui
    /// Only the name, the headline and a scene in the brand's style: no
    /// captures needed for the artwork.
    case scene

    var title: String {
        switch self {
        case .phone: String(localized: "A phone with the app")
        case .ui: String(localized: "The app, no device")
        case .scene: String(localized: "No app: a scene")
        }
    }

    /// The plan's note under the choice.
    var note: String {
        switch self {
        case .phone: String(localized: "A real screen from the captures, in a phone. Apple’s advice for search: show the app.")
        case .ui: String(localized: "The same real screen, cropped and floating, with no phone around it. Still shows the app; lighter.")
        case .scene: String(localized: """
            Only the name, the headline and a scene in the brand’s style. No captures needed for the artwork. \
            Best when the app’s look says more than its screens.
            """)
        }
    }

    /// The artwork needs captures.
    var needsCaptures: Bool { self != .scene }
}
