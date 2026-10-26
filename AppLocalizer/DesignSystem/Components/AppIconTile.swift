//
//  AppIconTile.swift
//  AppLocalizer
//

import SwiftUI

/// Stand-in for an app's icon: the API doesn't hand out icons directly, so
/// this shows the name's first letter on a rounded tile.
struct AppIconTile: View {
    let name: String
    var size: CGFloat = 28

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(Palette.tile)
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var initial: String {
        name.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
    }
}

#Preview {
    HStack {
        AppIconTile(name: "Bruma")
        AppIconTile(name: "AppLocalizer", size: 48)
    }
    .padding()
}
