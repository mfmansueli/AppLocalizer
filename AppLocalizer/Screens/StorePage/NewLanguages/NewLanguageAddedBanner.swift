//
//  NewLanguageAddedBanner.swift
//  AppLocalizer
//

import SwiftUI

/// On an added language's tab until it's pushed: "New language: the page is
/// created in App Store Connect when you push." with Don’t Add.
struct NewLanguageAddedBanner: View {
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.small) {
            UnsavedDot(size: 6)
                .accessibilityHidden(true)
            Text("New language: the page is created in App Store Connect when you push.")
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Don’t Add", action: onRemove)
                .buttonStyle(.link)
                .font(.callout)
                .accessibilityIdentifier("storePage.newLanguageAdded.remove")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small + 2)
        .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.banner, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.newLanguageAdded")
    }
}

#Preview {
    NewLanguageAddedBanner {}
        .padding()
        .frame(width: 720)
}
