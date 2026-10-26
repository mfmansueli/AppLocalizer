//
//  MCPProtocolVersion.swift
//  AppLocalizer
//

import Foundation

/// The MCP revisions this server speaks. They differ in features the server
/// doesn't use, so any of them works the same here.
enum MCPProtocolVersion {
    static let latest = "2025-11-25"
    static let supported: Set<String> = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"]

    /// The client's version when the server speaks it, else the latest,
    /// which the client may then refuse.
    static func negotiated(requested: String?) -> String {
        guard let requested, supported.contains(requested) else { return latest }
        return requested
    }
}
