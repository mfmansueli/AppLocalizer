//
//  ArtworkCheckSeverity.swift
//  AppLocalizer
//

import Foundation

/// An error is something Apple doesn't allow in the header or search
/// results placement: it blocks pushing that image. A warning is advice
/// and never blocks.
enum ArtworkCheckSeverity: String, Codable, Hashable, Sendable {
    case error
    case warning
}
