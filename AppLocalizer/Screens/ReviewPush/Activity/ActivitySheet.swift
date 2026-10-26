//
//  ActivitySheet.swift
//  AppLocalizer
//

import SwiftUI

/// Activity (the toolbar clock): every push from this Mac, newest first.
/// Restore Previous Values queues the old values for review; it never
/// pushes by itself.
struct ActivitySheet: View {
    @Environment(PushHistory.self) private var history
    @Environment(ChangeQueue.self) private var changes
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.title2.weight(.semibold))
                Text("Every push from this Mac, newest first.")
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding(Spacing.xLarge)
            Divider()
            if history.records.isEmpty {
                ContentUnavailableView(
                    "Nothing pushed yet",
                    systemImage: "clock",
                    description: Text("Pushes from Review & Push show here with their results.")
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(history.records) { record in
                            ActivityRow(
                                record: record,
                                onResults: { showResults() },
                                onRestore: { restore(record) }
                            )
                            Divider()
                        }
                    }
                }
            }
            Divider()
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(Spacing.large)
        }
        .frame(width: 660, height: 520)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity.sheet")
    }

    private func showResults() {
        dismiss()
        navigator.open(.subscriptionPricing, intent: .showResults)
    }

    /// Queues the old values and opens Review & Push on them.
    private func restore(_ record: PushRecord) {
        let restoring = record.restoringChanges()
        guard !restoring.isEmpty else { return }
        changes.upsert(contentsOf: restoring)
        navigator.showReviewAfterActivity()
    }
}
