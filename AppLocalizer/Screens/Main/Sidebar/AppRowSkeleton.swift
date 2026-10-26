//
//  AppRowSkeleton.swift
//  AppLocalizer
//

import SwiftUI

/// A placeholder sidebar row while the first sync runs.
struct AppRowSkeleton: View {
    var body: some View {
        HStack(spacing: 10) {
            SkeletonBlock(width: 28, height: 28, cornerRadius: 6)
            VStack(alignment: .leading, spacing: 5) {
                SkeletonBlock(width: 120, height: 9)
                SkeletonBlock(width: 86, height: 7)
            }
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(alignment: .leading) {
        AppRowSkeleton()
        AppRowSkeleton()
    }
    .padding()
}
