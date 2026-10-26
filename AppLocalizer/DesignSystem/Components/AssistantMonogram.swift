//
//  AssistantMonogram.swift
//  AppLocalizer
//

import SwiftUI

/// An assistant's two-letter tile, e.g. "CC" for Claude Code: label-colored,
/// so it reads in light, dark and Increase Contrast. Assistant chips, source
/// tags and the toolbar indicator start with it.
struct AssistantMonogram: View {
    let letters: String

    var body: some View {
        Text(letters)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(Color(nsColor: .windowBackgroundColor))
            .frame(width: 14, height: 14)
            .background(Palette.label, in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        AssistantMonogram(letters: "CC")
        AssistantMonogram(letters: "CU")
    }
    .padding()
}
