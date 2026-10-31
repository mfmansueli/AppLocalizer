//
//  AutopilotCaptionUpdate.swift
//  AppLocalizer
//

import Foundation

/// A caption the assistant wrote for a run: `slot` is 0-based.
struct AutopilotCaptionUpdate: Hashable, Sendable {
    var locale: String
    var slot: Int
    var headline: String
    var subhead: String?
}
