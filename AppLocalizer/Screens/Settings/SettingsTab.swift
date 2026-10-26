//
//  SettingsTab.swift
//  AppLocalizer
//

import Foundation

/// The Settings window's tabs. AI Assistants joins them with the local MCP
/// server.
enum SettingsTab: String, CaseIterable, Hashable, Sendable {
    case account
    case pricing
    case translation
    case general
}
