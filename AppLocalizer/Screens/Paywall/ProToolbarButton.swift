//
//  ProToolbarButton.swift
//  AppLocalizer
//

import SwiftUI

/// "Pro" in the toolbar while the person is on Free: opens the plans.
struct ProToolbarButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Pro", systemImage: "sparkles")
                .labelStyle(.titleAndIcon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.small)
                .frame(height: 24)
                .background(PaywallStyle.gradient, in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Upgrade to AppLocalizer Pro")
        .accessibilityLabel(Text("Upgrade to AppLocalizer Pro"))
        .accessibilityIdentifier("workspace.proButton")
    }
}

#Preview {
    ProToolbarButton {}.padding()
}
