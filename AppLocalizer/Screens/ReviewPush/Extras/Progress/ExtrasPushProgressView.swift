//
//  ExtrasPushProgressView.swift
//  AppLocalizer
//

import SwiftUI

/// The extras push under its cards: how many are done, a bar, each item in
/// flight with its step (one uploading, the rest with Apple or being
/// placed), the time so far and about how long is left, a pause for the
/// hourly budget, and the last few items that finished. Each reason
/// something failed shows once with the items it stopped, and once it's
/// over, Retry Failed.
struct ExtrasPushProgressView: View {
    let run: ExtrasPushRun

    /// The finished items listed while it runs.
    private static let recentCount = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            failures
            if run.isRunning {
                ProgressView(value: run.progress)
                    .progressViewStyle(.linear)
                    .accessibilityLabel(Text(run.countTitle))
                    .accessibilityIdentifier("review.extras.progress.bar")
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    live(now: context.date)
                }
                recent
            }
        }
        .padding(.horizontal, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("review.extras.progress")
    }

    private var header: some View {
        HStack(spacing: Spacing.small) {
            if run.isRunning { ProgressView().controlSize(.small) }
            Text(run.title).font(.caption.weight(.semibold))
            if run.isRunning {
                Text(run.countTitle)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .accessibilityIdentifier("review.extras.progress.count")
            }
            Spacer(minLength: Spacing.small)
            if run.phase == .finished, run.failedCount > 0 {
                Button("Retry Failed") { run.retryFailed() }.controlSize(.small)
            } else if run.isRunning {
                Button("Cancel Remaining") { run.cancelRemaining() }
                    .controlSize(.small)
                    .disabled(run.isCancelling)
            }
        }
    }

    /// Each reason something failed, once, with the items it stopped.
    @ViewBuilder
    private var failures: some View {
        let groups = run.failureGroups
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(groups) { group in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                        Image(systemName: "xmark.octagon.fill")
                            .foregroundStyle(Palette.danger)
                            .frame(width: 14)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(group.items.count) failed · \(group.reason)")
                                .foregroundStyle(Palette.danger)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                            Text(group.itemsTitle)
                                .foregroundStyle(Palette.label2)
                                .lineLimit(2)
                                .help(group.items.map(\.title).joined(separator: "\n"))
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .font(.caption)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("review.extras.progress.failures")
        }
    }

    /// The pause or cancel, each item in flight, and the time.
    private func live(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if let pause = run.pauseTitle {
                Label(pause, systemImage: "pause.circle")
                    .foregroundStyle(Palette.warning)
                    .accessibilityIdentifier("review.extras.progress.pause")
            } else if let cancelling = run.cancellingTitle {
                Label(cancelling, systemImage: "stop.circle")
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("review.extras.progress.cancelling")
            } else if let room = run.roomTitle {
                Label(room, systemImage: "hourglass")
                    .foregroundStyle(Palette.label2)
                    .accessibilityIdentifier("review.extras.progress.room")
            }
            ForEach(run.itemsInFlight) { item in
                if let detail = run.stepDetail(of: item, now: now) {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                        Image(systemName: icon(run.status(of: item)))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 14)
                            .accessibilityHidden(true)
                        Text(item.title).fontWeight(.medium).lineLimit(1)
                        Text(detail).foregroundStyle(Palette.label2).lineLimit(1).truncationMode(.tail)
                        Spacer(minLength: 0)
                    }
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("review.extras.progress.now.\(item.id)")
                }
            }
            if let time = run.timeTitle(now: now) {
                Text(time)
                    .foregroundStyle(Palette.label2)
                    .monospacedDigit()
                    .help(Text("The next file uploads while Apple processes the ones before it."))
                    .accessibilityIdentifier("review.extras.progress.time")
            }
        }
        .font(.caption)
    }

    /// The last few that finished, newest first.
    @ViewBuilder
    private var recent: some View {
        let events = run.events.suffix(Self.recentCount).reversed()
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(events)) { event in
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                        Image(systemName: event.status.isDone ? "checkmark.circle.fill" : event.status.isFailure ? "xmark.octagon.fill" : "minus.circle")
                            .foregroundStyle(event.status.isDone ? Palette.positive : event.status.isFailure ? Palette.danger : Palette.label3)
                            .frame(width: 14)
                            .accessibilityHidden(true)
                        Text(event.title).lineLimit(1)
                        Text("\(event.text) · took \(ExtrasPushRun.clock(event.seconds))")
                            .foregroundStyle(event.status.isFailure ? Palette.danger : Palette.label2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer(minLength: 0)
                        Text(event.date.formatted(date: .omitted, time: .standard))
                            .foregroundStyle(Palette.label3)
                    }
                    .help(event.text)
                }
            }
            .font(.caption)
            .monospacedDigit()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("review.extras.progress.recent")
        }
    }

    private func icon(_ status: ExtrasPushStatus) -> String {
        switch status {
        case .uploading: "arrow.up.circle"
        case .processing: "hourglass"
        case .placing: "square.and.arrow.down.on.square"
        case .waiting, .preparing, .done, .failed, .cancelled: "ellipsis.circle"
        }
    }
}
