//
//  AutopilotMomentRetake.swift
//  AppLocalizer
//

import Foundation

/// What `rerecord_moment` sends with a new take: the screen, the part of
/// the take that's the moment (from the settle time to the end when it
/// doesn't say) and why.
struct AutopilotMomentRetake: Hashable, Sendable {
    var screenID: String
    var start: Double?
    var end: Double?
    var reason: String?
}
