//
//  PushProgressView.swift
//  AppLocalizer
//

import SwiftUI

/// The review sheet once a push starts: overall progress, the hourly rate
/// meter and every change's status. Cancel Remaining while it runs; Retry
/// Failed, View Results and Done when it ends.
struct PushProgressView: View {
    let push: PushController
    let onViewResults: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(push.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("push.title")
                Text(push.subtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                ProgressView(value: push.progress)
                    .progressViewStyle(.linear)
                    .tint(push.failedCount > 0 && push.phase == .finished ? Palette.danger : Palette.accent)
                    .accessibilityLabel(Text("Push progress"))
                RateLimitMeter(rateLimit: push.rateLimit)
            }
            .padding(.horizontal, Spacing.xLarge)
            .padding(.top, Spacing.xLarge)
            .padding(.bottom, Spacing.medium)
            Divider()
            ScrollViewReader { proxy in
                List(push.items) { item in
                    PushProgressRow(item: item)
                        .listRowInsets(EdgeInsets())
                        .id(item.id)
                }
                .listStyle(.plain)
                .onChange(of: sendingID) { _, id in
                    guard let id else { return }
                    withAnimation { proxy.scrollTo(id, anchor: .center) }
                }
            }
            Divider()
            footer
                .padding(.horizontal, Spacing.xLarge)
                .padding(.vertical, Spacing.medium)
        }
    }

    private var sendingID: PendingChange.ID? {
        push.items.first { $0.status == .sending }?.id
    }

    private var footer: some View {
        HStack(spacing: Spacing.small) {
            if push.isRunning {
                Text("Keep working while this runs. App Store Connect applies one change per request.")
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                Spacer()
                Button("Cancel Remaining") { push.cancelRemaining() }
                    .accessibilityIdentifier("push.cancelRemaining")
            } else {
                Spacer()
                if push.failedCount > 0 {
                    Button("Retry Failed") { push.retryFailed() }
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
}
