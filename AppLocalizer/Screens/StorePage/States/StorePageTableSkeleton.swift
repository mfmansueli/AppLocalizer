//
//  StorePageTableSkeleton.swift
//  AppLocalizer
//

import SwiftUI

/// Placeholder rows while a table's data loads.
struct StorePageTableSkeleton: View {
    var rows = 10

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { index in
                HStack(spacing: Spacing.large) {
                    SkeletonBlock(width: 20, height: 14, cornerRadius: Radius.flag)
                    SkeletonBlock(width: index.isMultiple(of: 3) ? 120 : 90)
                    Spacer(minLength: Spacing.large)
                    ForEach(0..<6, id: \.self) { _ in
                        SkeletonBlock(width: 52)
                    }
                }
                .padding(.horizontal, Spacing.large)
                .frame(height: 32)
                Divider()
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }
}
