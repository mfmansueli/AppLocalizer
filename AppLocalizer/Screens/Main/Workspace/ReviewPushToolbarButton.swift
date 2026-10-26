//
//  ReviewPushToolbarButton.swift
//  AppLocalizer
//

import SwiftUI

/// "Review & Push" with the number of pending changes across all apps:
/// prominent glass while anything is waiting (⇧⌘P).
struct ReviewPushToolbarButton: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        if count > 0 {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private var button: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Label("Review & Push", systemImage: "arrow.up.circle")
                    .labelStyle(.titleAndIcon)
                if count > 0 {
                    Text(count, format: .number)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.white.opacity(0.25), in: Capsule())
                }
            }
        }
        .help("Review & Push (⇧⌘P)")
        .accessibilityLabel(Text("Review & Push"))
        .accessibilityValue(Text(count == 1 ? "1 pending change" : "\(count) pending changes"))
        .accessibilityIdentifier("workspace.reviewPushButton")
    }
}
