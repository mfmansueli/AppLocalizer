//
//  SetsGroupHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "LOCALIZED SETS 12", "RESTORED · NOT RENDERED 1", or the collapsible
/// "USE ENGLISH (U.S.) SCREENSHOTS 27 Show All" with its note.
struct SetsGroupHeader: View {
    let group: SetsGroup
    let isExpanded: Bool
    let stickyOffset: CGFloat
    var onToggle: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack(spacing: Spacing.xSmall) {
                Text(group.title)
                    .textCase(.uppercase)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.label2)
                Text(verbatim: "\(group.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Palette.label3)
                if let onToggle {
                    Button(isExpanded ? String(localized: "Hide") : String(localized: "Show All"), action: onToggle)
                        .buttonStyle(.link)
                        .font(.caption)
                        .accessibilityIdentifier("screenshots.sets.toggleFallback")
                }
            }
            .accessibilityElement(children: .contain)
            if let note = group.note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Palette.label3)
            }
        }
        .padding(.leading, SetsColumns.leading)
        .padding(.top, Spacing.large)
        .padding(.bottom, Spacing.small)
        .offset(x: stickyOffset)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screenshots.sets.group.\(group.kind.rawValue)")
    }
}
