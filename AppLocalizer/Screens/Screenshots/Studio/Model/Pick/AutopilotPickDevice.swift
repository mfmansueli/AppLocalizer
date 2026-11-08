//
//  AutopilotPickDevice.swift
//  AppLocalizer
//

import Foundation

/// The Screenshots tab's device switch: iPhone's picks (iPad, Mac and
/// Apple Vision Pro use the same moments), iPhone Duo's displays, and
/// Apple Watch's own screens.
enum AutopilotPickDevice: String, CaseIterable, Hashable, Sendable {
    case phones
    case duo
    case watch

    var title: String {
        switch self {
        case .phones: String(localized: "iPhone and iPad")
        case .duo: String(localized: "iPhone Duo")
        case .watch: String(localized: "Apple Watch")
        }
    }
}
