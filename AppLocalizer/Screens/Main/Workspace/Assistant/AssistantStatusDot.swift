//
//  AssistantStatusDot.swift
//  AppLocalizer
//

import SwiftUI

/// The Assistant button's dot: grey before setup, yellow while waiting for
/// a first call, green once connected. Never alone: the state is always in
/// words next to it or in the accessibility label.
struct AssistantStatusDot: View {
    let status: AssistantStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch status {
        case .notSetUp: Palette.label3
        case .waiting: Palette.warningMark
        case .connected, .ready: Palette.positive
        }
    }
}

#Preview {
    HStack {
        AssistantStatusDot(status: .notSetUp)
        AssistantStatusDot(status: .waiting(client: "Claude Code"))
        AssistantStatusDot(status: .connected(client: "Claude Code"))
        AssistantStatusDot(status: .ready(client: "Anthropic API"))
    }
    .padding()
}
