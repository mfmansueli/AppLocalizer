//
//  QueuedNewSubscriptionsList.swift
//  AppLocalizer
//

import SwiftUI

/// The new subscriptions waiting in Review & Push, each with its product
/// ID, duration and price, who proposed it, and Discard; then Review & Push.
struct QueuedNewSubscriptionsList: View {
    @Bindable var viewModel: PricingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Waiting in Review & Push")
                .font(.headline)
            Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.queuedNewSubscriptions.enumerated()), id: \.element.id) { index, change in
                        if index > 0 { Divider() }
                        row(change)
                    }
                }
            }
            HStack {
                Spacer()
                Button("Review & Push…", action: viewModel.onOpenReview)
                    .buttonBorderShape(.capsule)
                    .accessibilityIdentifier("pricing.newSubscriptions.review")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.newSubscriptions")
    }

    private func row(_ change: PendingChange) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(change.title)
                    .fontWeight(.medium)
                Text(productID(of: change))
                    .font(.caption.monospaced())
                    .foregroundStyle(Palette.label2)
                if let blocked = change.blockedReason {
                    Text(blocked)
                        .font(.caption)
                        .foregroundStyle(Palette.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Spacing.small)
            VStack(alignment: .trailing, spacing: 2) {
                Text(change.newValue)
                    .monospacedDigit()
                Text(change.source.title)
                    .font(.caption)
                    .foregroundStyle(Palette.label2)
            }
            Button {
                viewModel.discardNewSubscription(id: change.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Palette.label3)
            }
            .buttonStyle(.plain)
            .help(Text("Discard"))
            .accessibilityLabel(Text("Discard \(change.title)"))
            .accessibilityIdentifier("pricing.newSubscriptions.\(change.id).discard")
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.newSubscriptions.\(change.id)")
    }

    private func productID(of change: PendingChange) -> String {
        NewSubscriptionChangeBuilder.productID(of: change) ?? ""
    }
}
