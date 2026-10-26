//
//  PrivacyAssistantStatusLine.swift
//  AppLocalizer
//

import SwiftUI

/// "Claude Code connected · ~/Developer/Lumen · via AppLocalizer’s local MCP
/// server", or that none is, with Settings….
struct PrivacyAssistantStatusLine: View {
    let session: MCPClientSession?
    let isEnabled: Bool
    let appName: String

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.small) {
            Circle()
                .fill(session == nil ? Palette.label3 : Palette.positive)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if session == nil {
                SettingsLink {
                    Text("Settings…")
                }
                .controlSize(.small)
                .accessibilityIdentifier("appInformation.appPrivacy.settings")
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.appPrivacy.assistantStatus")
    }

    private var text: String {
        if let session {
            let folder = session.workingDirectory.map { " · \($0)" } ?? ""
            return String(localized: "\(session.displayName) connected\(folder) · via AppLocalizer’s local MCP server")
        }
        guard isEnabled else {
            return String(localized: "No assistant connected. The local server is off; turn it on in Settings, then connect Claude Code from \(appName)’s folder.")
        }
        return String(localized: "No assistant connected. The local server is on; connect Claude Code from \(appName)’s folder.")
    }
}
