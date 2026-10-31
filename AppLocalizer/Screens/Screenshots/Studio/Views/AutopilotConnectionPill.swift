//
//  AutopilotConnectionPill.swift
//  AppLocalizer
//

import SwiftUI

/// "● Claude Code Connected" or "● Design project Connect…" on the strip.
struct AutopilotConnectionPill: View {
    let title: String
    let status: String
    let isConnected: Bool
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xSmall) {
                Circle()
                    .fill(isConnected ? Palette.positive : Palette.label3)
                    .frame(width: 7, height: 7)
                Text(title).foregroundStyle(Palette.label)
                Text(status).foregroundStyle(Palette.label2)
            }
            .font(.callout)
            .lineLimit(1)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 3)
            .overlay(Capsule().strokeBorder(Palette.separator2, lineWidth: 0.5))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(Text(help))
        .accessibilityLabel(Text("\(title), \(status)"))
    }
}
