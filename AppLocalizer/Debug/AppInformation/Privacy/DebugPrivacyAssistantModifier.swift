//
//  DebugPrivacyAssistantModifier.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Puts the MCP server in the scene's state once the scene appears.
struct DebugPrivacyAssistantModifier: ViewModifier {
    let assistant: DebugPrivacyAssistant
    @Environment(MCPServerController.self) private var server

    func body(content: Content) -> some View {
        content.task { assistant.apply(to: server) }
    }
}
#endif
