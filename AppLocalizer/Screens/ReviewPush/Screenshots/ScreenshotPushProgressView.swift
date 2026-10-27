//
//  ScreenshotPushProgressView.swift
//  AppLocalizer
//

import SwiftUI

/// Review & Push once a screenshot push starts: overall progress, the
/// hourly rate meter, and a row per image (after any text changes pushed
/// alongside). Cancel Remaining while it runs; Retry Failed and Done when
/// it ends.
struct ScreenshotPushProgressView: View {
    let push: PushController
    let run: ScreenshotPushRun
    let onViewResults: () -> Void
    let onDone: () -> Void

    private var screenshots: ScreenshotPushController { push.screenshots }
    private var textRunning: Bool { push.phase == .running }
    private var isRunning: Bool { run.isRunning || textRunning }
    private var failedCount: Int { run.failedCount + push.failedCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("push.title")
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Palette.label2)
                        .accessibilityIdentifier("push.subtitle")
                }
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(failedCount > 0 && !isRunning ? Palette.danger : Palette.accent)
                    .accessibilityLabel(Text("Push progress"))
                RateLimitMeter(rateLimit: push.rateLimit)
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.top, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            Divider()
            List {
                ForEach(push.items) { item in
                    PushProgressRow(item: item)
                        .listRowInsets(EdgeInsets())
                }
                ForEach(run.items) { item in
                    ScreenshotPushProgressRow(item: item, image: screenshots.newImage(for: item.plan))
                        .listRowInsets(EdgeInsets())
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("push.list")
            Divider()
            footer
                .padding(.horizontal, Spacing.xLarge)
                .padding(.vertical, Spacing.medium)
        }
    }

    private var title: String {
        guard !push.items.isEmpty else { return run.title }
        let images = run.totalCount == 1 ? String(localized: "1 image") : String(localized: "\(run.totalCount) images")
        let changes = push.totalCount == 1 ? String(localized: "1 change") : String(localized: "\(push.totalCount) changes")
        return isRunning ? String(localized: "Pushing \(changes) and \(images)") : String(localized: "\(push.doneCount + run.doneCount) pushed · \(failedCount) failed")
    }

    private var subtitle: String {
        guard !push.items.isEmpty else { return run.subtitle }
        return isRunning ? run.subtitle : push.subtitle
    }

    private var progress: Double {
        let total = run.totalCount + push.totalCount
        guard total > 0 else { return 0 }
        return Double(run.finishedCount + push.finishedCount) / Double(total)
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            if isRunning {
                Text("New images are committed before the old ones are deleted, so a set is never left with a gap.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                Spacer()
                Button("Cancel Remaining") {
                    screenshots.cancelRemaining()
                    push.cancelRemaining()
                }
                .accessibilityIdentifier("push.cancelRemaining")
            } else {
                Text(doneNote)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                Spacer()
                if failedCount > 0 {
                    Button("Retry Failed") {
                        screenshots.retryFailed()
                        push.retryFailed()
                    }
                    .accessibilityIdentifier("push.retryFailed")
                }
                if push.changedPrices {
                    Button("View Results", action: onViewResults)
                        .accessibilityIdentifier("push.viewResults")
                }
                Button("Done", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("push.done")
            }
        }
        .buttonBorderShape(.capsule)
    }

    /// "Retry sends only the failed images.", or when it all went: "Live on
    /// the App Store once version 1.4 is released."
    private var doneNote: String {
        if failedCount > 0 { return String(localized: "Retry sends only the failed images.") }
        let versions = Set(run.plans.map(\.version.versionString))
        guard run.doneCount > 0, versions.count == 1, let version = versions.first else { return "" }
        return String(localized: "Live on the App Store once version \(version) is released.")
    }
}
