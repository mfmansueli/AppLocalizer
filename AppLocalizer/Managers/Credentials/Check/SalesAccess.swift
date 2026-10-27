//
//  SalesAccess.swift
//  AppLocalizer
//

import Foundation

/// Whether a key's role can read Sales and Trends. The API doesn't tell a
/// key its role, so `LiveKeyChecker` finds out by asking for a sales report.
enum SalesAccess: String, Codable, Hashable, Sendable {
    case readable
    /// 403: price suggestions use purchasing power alone.
    case notAllowed
    /// The probe failed some other way (a server error, the network).
    case unknown
}
