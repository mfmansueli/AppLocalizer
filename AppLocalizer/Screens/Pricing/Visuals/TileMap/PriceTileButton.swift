//
//  PriceTileButton.swift
//  AppLocalizer
//

import SwiftUI

/// One territory on the tile map: its two-letter code on its metric's
/// color. VoiceOver reads the territory and its price ("Brazil: R$ 109,90").
struct PriceTileButton: View {
    let tile: PriceTileMap.Tile
    let isSelected: Bool
    /// The filters hide it from the table.
    let isDimmed: Bool
    let onHover: () -> Void
    let onSelect: () -> Void

    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: onSelect) {
            Text(tile.code)
                .font(.system(size: 8, weight: .semibold).monospaced())
                .foregroundStyle(tile.usesLightText ? Color.white : Palette.label)
                .frame(width: PriceTileMapView.tileSize, height: PriceTileMapView.tileSize)
                .background(fill, in: RoundedRectangle(cornerRadius: Radius.badge - 1, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.badge - 1, style: .continuous)
                        .strokeBorder(isSelected ? Palette.label : edge, lineWidth: isSelected ? 2 : 0.5)
                }
        }
        .buttonStyle(.plain)
        .opacity(isDimmed ? 0.3 : 1)
        .onHover { isHovering in
            if isHovering { onHover() }
        }
        .accessibilityLabel(tile.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityIdentifier("pricing.tile.\(tile.id)")
    }

    private var fill: Color {
        switch tile.tone {
        case .neutral: Palette.fill2
        case .below: Palette.content.mix(with: Palette.decreaseMark, by: tile.colorShare)
        case .above: Palette.content.mix(with: Palette.increaseMark, by: tile.colorShare)
        case .scale: Palette.content.mix(with: Palette.accent, by: tile.colorShare)
        }
    }

    private var edge: Color {
        contrast == .increased ? Palette.separator2 : Palette.separator
    }
}
