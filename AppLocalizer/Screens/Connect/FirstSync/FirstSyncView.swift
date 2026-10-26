//
//  FirstSyncView.swift
//  AppLocalizer
//

import SwiftUI

/// "Loading your apps…": shown in place of the library right after a key
/// is connected, until every app's summaries have loaded once.
struct FirstSyncView: View {
    let progress: FirstSyncProgress

    var body: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()
                .controlSize(.large)
            Text("Loading your apps…")
                .font(.title3.weight(.medium))
            ProgressView(value: progress.fraction)
                .progressViewStyle(.linear)
                .frame(width: 280)
                .accessibilityLabel(Text("Loading your apps"))
                .accessibilityIdentifier("sync.progress")
            Text(progress.detail)
                .font(.footnote)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
            Text("The first sync reads every territory’s price, so it takes about a minute.")
                .font(.caption)
                .foregroundStyle(Palette.label3)
        }
        .padding(Spacing.xxxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("AppLocalizer")
        .navigationSubtitle("Loading your apps…")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sync.view")
    }
}

#Preview {
    FirstSyncView(progress: FirstSyncProgress(appCount: 6, syncedCount: 2))
        .frame(width: 900, height: 600)
}
