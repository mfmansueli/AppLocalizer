//
//  StudioDebugAssistants.swift
//  AppLocalizer
//

#if DEBUG
import SwiftUI

/// Puts the MCP server in `state` once a Studio scene appears: Claude Code
/// connected, or no assistant.
struct StudioDebugAssistants: ViewModifier {
    let state: AssistantsDebugState
    @Environment(MCPServerController.self) private var server

    func body(content: Content) -> some View {
        content.task { state.apply(to: server) }
    }
}
#endif
