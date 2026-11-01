//
//  AppIconTile.swift
//  AppLocalizer
//

import SwiftUI

/// An app's icon: the image App Store Connect serves when there is one
/// (trimmed to fill the tile, as a Mac build's icon has a margin), a symbol
/// on a gradient for sample apps, otherwise the name's first letter on a
/// rounded tile.
struct AppIconTile: View {
    let name: String
    var icon: AppIcon?
    var size: CGFloat = 28

    var body: some View {
        Group {
            switch icon {
            case let .remote(url):
                RemoteAppIconImage(url: url) {
                    letterTile
                }
            case let .symbol(symbol, top, bottom):
                LinearGradient(colors: [color(top), color(bottom)], startPoint: .top, endPoint: .bottom)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: size * 0.46, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            case nil:
                letterTile
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .accessibilityHidden(true)
    }

    private var letterTile: some View {
        Palette.tile
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.label2)
            }
    }

    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }

    private func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

#Preview {
    HStack {
        AppIconTile(name: "Bruma")
        AppIconTile(name: "Lumen Journal", icon: .symbol("moon.fill", top: 0x7C86FF, bottom: 0x3A2FB8), size: 48)
        AppIconTile(name: "AppLocalizer", size: 64)
    }
    .padding()
}
