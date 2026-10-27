//
//  LastPushCard.swift
//  AppLocalizer
//

import SwiftUI

/// When this app was last pushed, what went out and whether it all worked.
struct LastPushCard: View {
    let record: PushRecord?
    let onViewActivity: () -> Void

    var body: some View {
        Card {
            OverviewCardTitle(title: String(localized: "Last push"))
            if let record {
                Text(record.date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text(record.title)
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
                if record.failedCount == 0 {
                    Pill(text: String(localized: "All succeeded"))
                } else {
                    Pill(text: String(localized: "\(record.succeededCount) succeeded · \(record.failedCount) failed"), style: .danger)
                }
            } else {
                Text("Nothing pushed yet")
                    .font(.title3.weight(.semibold))
                Text("Your first push will show here.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.label2)
            }
            Button("View Activity", action: onViewActivity)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        }
        .accessibilityIdentifier("overview.lastPushCard")
    }
}
