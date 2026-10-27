//
//  PendingChangesCard.swift
//  AppLocalizer
//

import SwiftUI

/// How many of this app's changes wait in Review & Push.
struct PendingChangesCard: View {
    let count: Int
    let onReview: () -> Void

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "Pending changes"))
            if count > 0 {
                HStack(spacing: 6) {
                    UnsavedDot()
                    Text(count == 1 ? String(localized: "1 waiting to be pushed") : String(localized: "\(count) waiting to be pushed"))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                Button("Review & Push…", action: onReview)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
            } else {
                Text("Nothing waiting")
                    .font(.title3.weight(.semibold))
                Text("Edits in Pricing, Store Page and App Information collect here until you push them.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("overview.pendingChangesCard")
    }
}
