//
//  GlossaryTermChip.swift
//  AppLocalizer
//

import SwiftUI

/// A "Don't translate" term with its × to remove it.
struct GlossaryTermChip: View {
    let term: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            Text(term)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 7, weight: .bold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(term)"))
        }
        .font(.caption)
        .padding(.horizontal, Spacing.small)
        .frame(height: 20)
        .background(Palette.fill2, in: Capsule())
        .accessibilityElement(children: .contain)
    }
}
