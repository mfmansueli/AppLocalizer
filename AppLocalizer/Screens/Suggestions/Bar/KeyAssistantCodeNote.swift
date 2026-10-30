//
//  KeyAssistantCodeNote.swift
//  AppLocalizer
//

import SwiftUI

/// Under the suggestion bar with an API key, where some answers come from
/// the code: a key doesn't read it, so those need an MCP assistant.
struct KeyAssistantCodeNote: View {
    let count: Int
    /// "Lumen Journal".
    let appName: String
    let onAddAssistant: () -> Void

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: "info.circle")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Add an MCP Assistant…", action: onAddAssistant)
                .controlSize(.small)
                .accessibilityIdentifier("suggestions.addAssistant")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill1, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("suggestions.keyNote")
    }

    /// "4 answers here come from Lumen Journal’s code. An API key doesn’t
    /// read code, so these need an assistant that does, like Claude Code."
    var text: String {
        count == 1
            ? String(localized: "1 answer here comes from \(appName)’s code. An API key doesn’t read code, so it needs an assistant that does, like Claude Code.")
            : String(localized: "\(count) answers here come from \(appName)’s code. An API key doesn’t read code, so these need an assistant that does, like Claude Code.")
    }
}

#Preview {
    KeyAssistantCodeNote(count: 4, appName: "Lumen Journal", onAddAssistant: {})
        .padding()
        .frame(width: 760)
}
