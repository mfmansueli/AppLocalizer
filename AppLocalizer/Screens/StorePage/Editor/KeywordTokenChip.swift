//
//  KeywordTokenChip.swift
//  AppLocalizer
//

import SwiftUI

/// One keyword token with its × to remove it. Duplicates are yellow; words
/// already in the name or subtitle are struck through, since the App Store
/// indexes those already.
struct KeywordTokenChip: View {
    let token: KeywordToken
    let isEditable: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 3) {
            Text(token.text)
                .strikethrough(token.state == .inNameOrSubtitle)
                .lineLimit(1)
            if isEditable {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 14, height: 14)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Remove \(token.text)"))
            }
        }
        .font(.callout)
        .foregroundStyle(foreground)
        .padding(.leading, Spacing.small)
        .padding(.trailing, isEditable ? Spacing.xxSmall : Spacing.small)
        .frame(height: 22)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(token.accessibilityLabel))
    }

    private var foreground: Color {
        switch token.state {
        case .useful: Palette.label
        case .duplicate: Palette.warning
        case .inNameOrSubtitle: Palette.label3
        }
    }

    private var background: Color {
        switch token.state {
        case .useful: Palette.fill2
        case .duplicate: Palette.warningTint
        case .inNameOrSubtitle: Palette.fill1
        }
    }

    /// The legend's "word" chip in a state.
    static func sample(state: KeywordTokenState) -> some View {
        KeywordTokenChip(token: KeywordToken(index: 0, text: String(localized: "word"), state: state), isEditable: false) {}
            .scaleEffect(0.85)
            .accessibilityHidden(true)
    }
}
