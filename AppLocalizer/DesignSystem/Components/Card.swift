//
//  Card.swift
//  AppLocalizer
//

import SwiftUI

/// A raised, rounded container with a hairline edge: overview cards, the
/// rating preview, inspector groups. Content is never glass.
struct Card<Content: View>: View {
    var padding: CGFloat = Spacing.large
    @ViewBuilder var content: () -> Content

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Palette.raised, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(contrast == .increased ? Palette.separator2 : Palette.separator, lineWidth: contrast == .increased ? 1 : 0.5)
        }
        // One element, so an identifier on the card doesn't land on every
        // text inside it.
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    Card {
        Text("Store page").font(.subheadline).foregroundStyle(.secondary)
        Text("10 of 39 locales · 88%").font(.title3.weight(.semibold))
    }
    .frame(width: 300)
    .padding()
}
