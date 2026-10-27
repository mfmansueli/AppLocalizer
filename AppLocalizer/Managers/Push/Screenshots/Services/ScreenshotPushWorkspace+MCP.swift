//
//  ScreenshotPushWorkspace+MCP.swift
//  AppLocalizer
//

import Foundation

extension ScreenshotPushWorkspace {
    /// The account an assistant workspace describes.
    init(_ workspace: MCPWorkspace) {
        self.init(teamName: workspace.teamName, services: workspace.services, apps: workspace.apps)
    }

    /// Attaches `workspace`'s account to `controller`; nothing when there's
    /// no window for an account yet.
    @MainActor
    static func attach(_ workspace: MCPWorkspace?, to controller: ScreenshotPushController) {
        guard let workspace else { return }
        controller.attach(ScreenshotPushWorkspace(workspace))
    }
}
