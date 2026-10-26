//
//  PushProgressRow.swift
//  AppLocalizer
//

import SwiftUI

/// One change in a running push: queued ○, sending (spinner), done ✓, or
/// failed with Apple's code and detail underneath. A change with an option
/// says its step on the right instead of its value: Queued → Sending… →
/// Publishing… → Published, or Saved as a draft.
struct PushProgressRow: View {
    let item: PushItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            statusIcon
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Text(item.change.title)) \(Text("· \(item.change.group)").foregroundStyle(Palette.label2))")
                    .lineLimit(1)
                if let detail {
                    Text(detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(detailColor)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Spacing.small)
            Text(trailingText)
                .foregroundStyle(Palette.label2)
                .monospacedDigit()
                .lineLimit(1)
                .frame(maxWidth: 220, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.xSmall + 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.change.title) · \(item.change.group), \(statusText), \(trailingText)"))
        .accessibilityIdentifier("push.row.\(item.id)")
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .queued:
            Image(systemName: "circle")
                .foregroundStyle(Palette.label3)
        case .sending:
            ProgressView()
                .controlSize(.mini)
        case .done:
            Image(systemName: "checkmark")
                .foregroundStyle(Palette.label2)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(Palette.danger)
        case .conflict:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.warning)
        case .notSent:
            Image(systemName: "minus.circle")
                .foregroundStyle(Palette.label3)
        }
    }

    /// The new value, or the option's step for a change that has one.
    private var trailingText: String {
        guard let option = item.change.option else { return item.change.newValue }
        switch item.status {
        case .queued: return String(localized: "Queued")
        case .sending: return item.isSendingOption ? option.progressTitle : String(localized: "Sending…")
        case .done: return option.finishedTitle
        case .failed, .conflict, .notSent: return item.change.newValue
        }
    }

    private var detail: String? {
        switch item.status {
        case let .failed(text): text
        case .conflict: String(localized: "Changed in App Store Connect since your last fetch. It's back in review.")
        case let .notSent(reason): reason
        case .queued, .sending, .done: nil
        }
    }

    private var detailColor: Color {
        if case .failed = item.status { return Palette.danger }
        return Palette.label2
    }

    private var statusText: String {
        switch item.status {
        case .queued: String(localized: "Queued")
        case .sending: String(localized: "Sending")
        case .done: String(localized: "Done")
        case let .failed(text): String(localized: "Failed: \(text)")
        case .conflict: String(localized: "Conflict")
        case let .notSent(reason): String(localized: "Not sent: \(reason)")
        }
    }
}
