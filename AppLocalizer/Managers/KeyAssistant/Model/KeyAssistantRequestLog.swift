//
//  KeyAssistantRequestLog.swift
//  AppLocalizer
//

import Foundation

/// One request sent with the key, for the Assistant popover's Recent
/// Requests: "Store Page · English, German", 9.4k tokens, 2 min ago.
struct KeyAssistantRequestLog: Hashable, Codable, Identifiable, Sendable {
    var id = UUID()
    var title: String
    var tokens: Int
    var date: Date
}
