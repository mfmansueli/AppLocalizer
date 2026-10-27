//
//  AppInformationPageSkeleton.swift
//  AppLocalizer
//

import SwiftUI

/// A page's shape while App Store Connect's values load.
struct AppInformationPageSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                SkeletonBlock(width: 160, height: 18)
                SkeletonBlock(width: 340)
            }
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: Spacing.small) {
                    SkeletonBlock(width: 90, height: 8)
                    SkeletonBlock(height: 120, cornerRadius: Radius.card - 2)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Loading"))
        .accessibilityIdentifier("appInformation.loading")
    }
}

#Preview {
    AppInformationPageSkeleton()
        .padding()
        .frame(width: 600)
}
