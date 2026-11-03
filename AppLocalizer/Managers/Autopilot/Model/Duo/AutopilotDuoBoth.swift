//
//  AutopilotDuoBoth.swift
//  AppLocalizer
//

import Foundation

/// How iPhone Duo's two displays appear when the plan shows both.
enum AutopilotDuoBoth: String, Codable, CaseIterable, Hashable, Sendable {
    /// The unfolded Duo with the folded cover beside it: one image per
    /// screen, the same count as the other devices.
    case sideBySide
    /// Inner, then cover, for each screen; capped at Apple's 10 a device,
    /// so with more than 5 screens some screens get no cover one.
    case separate

    var title: String {
        switch self {
        case .sideBySide: String(localized: "Side by side in each screenshot")
        case .separate: String(localized: "As separate screenshots")
        }
    }
}
