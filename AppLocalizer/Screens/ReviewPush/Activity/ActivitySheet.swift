//
//  ActivitySheet.swift
//  AppLocalizer
//

import SwiftUI

/// Activity (the toolbar clock): every push from this Mac, newest first.
/// Restore Previous Values queues the old values for review; Restore
/// Previous Screenshots… picks a locale's kept set. Neither pushes by
/// itself.
struct ActivitySheet: View {
    @Environment(PushHistory.self) private var history
    @Environment(ChangeQueue.self) private var changes
    @Environment(WorkspaceNavigator.self) private var navigator
    @Environment(PushController.self) private var push
    @Environment(\.dismiss) private var dismiss
    @State private var restoringScreenshots: ScreenshotRestorePresentation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Activity")
                    .font(.title2.weight(.semibold))
                Text(subtitle)
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
                                onRestore: { restore(record) },
                                onRestoreScreenshots: push.screenshots.canPush
                                    ? { restoringScreenshots = ScreenshotRestorePresentation(recordID: record.id) }
                                    : nil
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
        .sheet(item: $restoringScreenshots) { presentation in
            if let record = history.records.first(where: { $0.id == presentation.recordID }) {
                ScreenshotRestoreSheet(record: record, locale: presentation.locale) {
                    restoringScreenshots = nil
                    navigator.showReviewAfterActivity()
                }
            }
        }
        .task(id: push.screenshots.workspace?.teamName) {
            if let pending = push.screenshots.pendingRestore {
                push.screenshots.pendingRestore = nil
                restoringScreenshots = pending
            }
        }
    }

    private var subtitle: String {
        guard history.records.contains(where: { $0.screenshots != nil }) else { return String(localized: "Every push from this Mac, newest first.") }
        return String(localized: "Every push from this Mac, newest first. Replaced screenshots are kept on this Mac so you can put them back.")
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
