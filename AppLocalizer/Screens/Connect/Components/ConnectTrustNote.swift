//
//  ConnectTrustNote.swift
//  AppLocalizer
//

import SwiftUI

/// "The key never leaves this Mac…", next to the Connect button.
struct ConnectTrustNote: View {
    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Image(systemName: "lock")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            Text("The key never leaves this Mac. It’s kept in the Keychain, and every request is signed locally and sent straight to Apple.")
                .font(.footnote)
                .foregroundStyle(Palette.label2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .help(Text("Each request carries a short-lived token (ES256, 15 minutes) signed on this Mac with the private key."))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ConnectTrustNote()
        .frame(width: 340)
        .padding()
}
