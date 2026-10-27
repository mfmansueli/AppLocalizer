//
//  DebugPrivacyAssistant.swift
//  AppLocalizer
//

#if DEBUG
import Foundation

/// The MCP server in an App Privacy scene: Claude Code connected in
/// Lumen's folder, or the server on with no assistant.
enum DebugPrivacyAssistant {
    case connected
    case serverOnly

    @MainActor
    func apply(to server: MCPServerController) {
        switch self {
        case .connected: AssistantsDebugState.paired.apply(to: server)
        case .serverOnly: server.setEnabled(true)
        }
    }
}
#endif
