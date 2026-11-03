//
//  StudioArtworkChip.swift
//  AppLocalizer
//

import SwiftUI

/// "New · header", "New", "English (U.S.)": a chip that reads on any
/// artwork, light on dark.
struct StudioArtworkChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.92), in: Capsule())
            .lineLimit(1)
    }
}
