//
//  AccessibilitySkeletonCard.swift
//  AppLocalizer
//

import SwiftUI

/// A family card's shape while the declarations load.
struct AccessibilitySkeletonCard: View {
    var body: some View {
        Card {
            HStack {
                SkeletonBlock(width: 90, height: 12)
                Spacer()
                SkeletonBlock(width: 70, height: 14)
            }
            SkeletonBlock(width: 190)
            HStack(spacing: Spacing.xxSmall) {
                SkeletonBlock(width: 64, height: 16, cornerRadius: 8)
                SkeletonBlock(width: 80, height: 16, cornerRadius: 8)
                SkeletonBlock(width: 70, height: 16, cornerRadius: 8)
            }
            SkeletonBlock(width: 120, height: 16, cornerRadius: 8)
            SkeletonBlock(width: 48, height: 20, cornerRadius: 6)
                .padding(.top, Spacing.xxSmall)
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    AccessibilitySkeletonCard()
        .frame(width: 340)
        .padding()
}
