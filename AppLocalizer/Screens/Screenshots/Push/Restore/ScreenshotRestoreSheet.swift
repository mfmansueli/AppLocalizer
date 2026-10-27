//
//  ScreenshotRestoreSheet.swift
//  AppLocalizer
//

import SwiftUI

/// Restore Previous Screenshots… (760 pt): every locale a screenshot push
/// touched, with what it kept for each. Picking a locale shows its kept
/// set per display type; queueing sends it back through Review & Push and
/// pins the locale. A locale that had none says how to go back to that.
struct ScreenshotRestoreSheet: View {
    let record: PushRecord
    /// The locale to start on; the first with kept screenshots otherwise.
    var locale: String?
    let onQueued: () -> Void

    @Environment(PushController.self) private var push
    @Environment(\.dismiss) private var dismiss
    @State private var backup: ScreenshotBackup?
    @State private var selected: String?
    @State private var displayType: ScreenshotDisplayType = .iPhone
    @State private var isQueueing = false

    private var controller: ScreenshotPushController { push.screenshots }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Restore previous screenshots")
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
            }
            .padding(Spacing.xLarge)
            Divider()
            HStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(choices) { choice in
                            ScreenshotRestoreLocaleRow(choice: choice, isSelected: choice.id == current?.id) {
                                selected = choice.id
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(width: 250)
                .accessibilityIdentifier("restore.locales")
                Divider()
                if let current {
                    ScreenshotRestoreStage(choice: current, backupDate: record.date, displayType: $displayType, thumbnails: controller.backupThumbnails)
                } else {
                    Spacer()
                }
            }
            Divider()
            HStack(spacing: Spacing.small) {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(queueTitle) { queue() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!(current?.hasImages ?? false) || isQueueing)
                    .accessibilityIdentifier("restore.queue")
            }
            .buttonBorderShape(.capsule)
            .padding(Spacing.large)
        }
        .frame(width: 760, height: 540)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("restore.sheet")
        .task {
            await controller.loadAppsIfNeeded()
            backup = controller.backup(for: record)
            if selected == nil { selected = locale ?? choices.first(where: \.hasImages)?.id ?? choices.first?.id }
            if let backup { controller.loadBackupThumbnails(backup.images, appID: record.appID) }
        }
    }

    private var choices: [ScreenshotRestoreChoice] {
        guard let summary = record.screenshots else { return [] }
        return ScreenshotRestoreChoice.choices(for: summary, backup: backup, primaryLocaleName: controller.primaryLocaleName(for: record.appID))
    }

    private var current: ScreenshotRestoreChoice? {
        choices.first { $0.id == selected } ?? choices.first
    }

    /// "From before the push on Oct 12, 2026 · 14:32. Pick a locale; its
    /// screenshots go back through Review & Push."
    private var subtitle: String {
        let date = record.date.formatted(.dateTime.month(.abbreviated).day().year())
        let time = record.date.formatted(date: .omitted, time: .shortened)
        return String(localized: "From before the push on \(date) · \(time). Pick a locale; its screenshots go back through Review & Push.")
    }

    /// "Queue 10 Screenshots for Review".
    private var queueTitle: String {
        let count = current?.images.count ?? 0
        return count == 1 ? String(localized: "Queue 1 Screenshot for Review") : String(localized: "Queue \(count) Screenshots for Review")
    }

    private func queue() {
        guard let current, let backup else { return }
        isQueueing = true
        Task {
            let queued = await controller.queueRestore(locale: current.locale, from: backup, appID: record.appID)
            isQueueing = false
            if queued { onQueued() }
        }
    }
}
