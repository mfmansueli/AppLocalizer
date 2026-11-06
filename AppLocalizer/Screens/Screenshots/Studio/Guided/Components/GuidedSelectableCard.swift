//
//  GuidedSelectableCard.swift
//  AppLocalizer
//

import SwiftUI

/// The guided sheet's cards: raised, with a thin outline, or the accent's
/// when chosen.
struct GuidedSelectableCard: ViewModifier {
    var isSelected = false
    var padding: CGFloat = Spacing.medium
    var radius: CGFloat = Radius.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Palette.raised, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Palette.separator, lineWidth: isSelected ? 2 : 0.5)
            }
    }
}
