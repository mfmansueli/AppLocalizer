//
//  SkeletonBlock.swift
//  AppLocalizer
//

import SwiftUI

/// A grey placeholder shape while content loads: sidebar rows, overview
/// cards, table rows.
struct SkeletonBlock: View {
    var width: CGFloat?
    var height: CGFloat = 10
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Palette.skeleton)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        SkeletonBlock(width: 120)
        SkeletonBlock(width: 80, height: 8)
        SkeletonBlock(height: 120, cornerRadius: Radius.card)
    }
    .padding()
    .frame(width: 300)
}
