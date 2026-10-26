//
//  ActivityRow.swift
//  AppLocalizer
//

import SwiftUI

/// One push in Activity: what changed, the app, when and how many, whether
/// it all succeeded, and Results / Restore Previous Values.
struct ActivityRow: View {
    let record: PushRecord
    let onResults: () -> Void
    let onRestore: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: "arrow.up.circle")
                .foregroundStyle(Palette.label2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(record.title)
                    .font(.headline)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                if record.failedCount > 0 {
                    Pill(text: String(localized: "\(record.failedCount) failed"), style: .danger)
                        .padding(.top, 2)
                } else {
                    Pill(text: String(localized: "All succeeded"), systemImage: "checkmark", style: .neutral)
                        .padding(.top, 2)
                }
                ForEach(record.failedChanges) { change in
                    Text("\(change.title): \(record.failures[change.id] ?? "")")
                        .font(.caption.monospaced())
                        .foregroundStyle(Palette.danger)
                        .textSelection(.enabled)
                }
            }
            Spacer()
            HStack(spacing: Spacing.small) {
                if record.changedPrices {
                    Button("Results", action: onResults)
                        .accessibilityIdentifier("activity.results")
                }
                Button(action: onRestore) {
                    Label("Restore Previous Values", systemImage: "arrow.uturn.backward")
                }
                .disabled(record.restoringChanges().isEmpty)
                .help(record.restoringChanges().isEmpty
                    ? String(localized: "These values can't be restored from here.")
                    : String(localized: "Queues the values from before this push for review."))
                .accessibilityIdentifier("activity.restore")
            }
            .buttonBorderShape(.capsule)
            .controlSize(.small)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.medium)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity.record.\(record.id.uuidString)")
    }

    private var details: String {
        let date = record.date.formatted(.dateTime.month(.abbreviated).day().year())
        let time = record.date.formatted(date: .omitted, time: .shortened)
        let count = record.changeCount == 1 ? String(localized: "1 change") : String(localized: "\(record.changeCount) changes")
        return "\(record.appName) · \(date) · \(time) · \(count)"
    }
}
