//
//  MCPClientKind+Xcode.swift
//  AppLocalizer
//

import Foundation

extension MCPClientKind {
    /// Runs on this Mac with a shell, so it can build the app and drive
    /// Simulator for Screenshot Autopilot.
    var canRunXcode: Bool {
        switch self {
        case .claudeCode, .cursor, .codex: true
        case .claudeDesktop, .other: false
        }
    }
}
