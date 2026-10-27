//
//  AccessibilityStateBadge.swift
//  AppLocalizer
//

import SwiftUI

/// A family card's state: outlined when not declared, green text when
/// published, neutral otherwise.
struct AccessibilityStateBadge: View {
    let state: AccessibilityCardState

    var body: some View {
        Text(state.title)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(background, in: RoundedRectangle(cornerRadius: Radius.badge, style: .continuous))
            .overlay {
                if state == .notDeclared {
                    RoundedRectangle(cornerRadius: Radius.badge, style: .continuous).strokeBorder(Palette.separator2, lineWidth: 1)
                }
            }
            .accessibilityLabel(Text("State: \(state.title)"))
    }

    private var foreground: Color {
        state == .published ? Palette.positive : Palette.label2
    }

    private var background: Color {
        switch state {
        case .notDeclared: .clear
        case .published: Palette.positive.opacity(0.14)
        case .draft, .draftCantPublish, .publishedChangesWaiting: Palette.fill2
        }
    }
}

#Preview {
    VStack(alignment: .trailing) {
        AccessibilityStateBadge(state: .notDeclared)
        AccessibilityStateBadge(state: .draft)
        AccessibilityStateBadge(state: .draftCantPublish)
        AccessibilityStateBadge(state: .published)
        AccessibilityStateBadge(state: .publishedChangesWaiting)
    }
    .padding()
}
