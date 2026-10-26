//
//  OverviewSkeleton.swift
//  AppLocalizer
//

import SwiftUI

/// Placeholder header and cards while the first summaries load.
struct OverviewSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            SkeletonBlock(width: 260, height: 28, cornerRadius: 6)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Metrics.overviewCardMinimumWidth), spacing: 14)], spacing: 14) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonBlock(height: 120, cornerRadius: Radius.card)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Loading"))
        .accessibilityIdentifier("overview.skeleton")
    }
}
