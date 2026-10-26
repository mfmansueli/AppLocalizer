//
//  KeyAccessCheck.swift
//  AppLocalizer
//

import Foundation

/// What Connect or "Test Connection" found out about a key: it works, how
/// many apps it sees, how fast Apple answered, and whether it can read Sales
/// and Trends.
struct KeyAccessCheck: Codable, Hashable, Sendable {
    var appCount: Int
    /// The round trip of the apps request.
    var milliseconds: Int
    var salesAccess: SalesAccess
    var date: Date

    /// "Connected · 6 apps · 182 ms".
    var connectionSummary: String {
        let apps = appCount == 1 ? String(localized: "1 app") : String(localized: "\(appCount) apps")
        return String(localized: "Connected · \(apps) · \(milliseconds) ms")
    }

    /// The role line under a saved key.
    var salesSummary: String {
        switch salesAccess {
        case .readable: String(localized: "Can manage apps and read Sales and Trends")
        case .notAllowed: String(localized: "Can’t read Sales and Trends, so price suggestions use purchasing power only")
        case .unknown: String(localized: "Couldn’t check access to Sales and Trends")
        }
    }
}
