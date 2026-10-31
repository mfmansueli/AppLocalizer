//
//  AutopilotLocaleCheck.swift
//  AppLocalizer
//

import Foundation

/// One language checked with the chosen direction.
struct AutopilotLocaleCheck: Hashable, Sendable {
    var status: AutopilotLocaleStatus
    var overflows: [AutopilotOverflow]
}
