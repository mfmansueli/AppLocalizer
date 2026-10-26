//
//  InitialsTile.swift
//  AppLocalizer
//

import SwiftUI

/// A team's initials on a dark rounded square ("NS"), for the account
/// switcher and Settings → Account.
struct InitialsTile: View {
    let initials: String
    var size: CGFloat = 28

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.39, weight: .bold))
            .foregroundStyle(Palette.window)
            .frame(width: size, height: size)
            .background(Palette.label, in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        InitialsTile(initials: "NS")
        InitialsTile(initials: "BA", size: 30)
    }
    .padding()
}
