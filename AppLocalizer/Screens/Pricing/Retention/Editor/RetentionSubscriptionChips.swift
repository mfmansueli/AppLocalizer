//
//  RetentionSubscriptionChips.swift
//  AppLocalizer
//

import SwiftUI

/// The subscriptions that show the message, one chip each. A subscription
/// shows one message, so checking it here takes it from another; one App
/// Store Connect already shows the message on can't be unchecked.
struct RetentionSubscriptionChips: View {
    let model: RetentionModel
    let message: RetentionMessage

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            Text("Subscriptions")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .frame(width: 96, alignment: .leading)
            FlowLayout(spacing: Spacing.xSmall) {
                ForEach(model.subscriptions) { subscription in
                    chip(subscription)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.subscriptions")
    }

    private func chip(_ subscription: RetentionSubscription) -> some View {
        let isOn = message.subscriptionIDs.contains(subscription.id)
        let isLocked = model.isAssignedRemotely(subscription.id)
        return Button {
            model.toggleSubscription(subscription.id)
        } label: {
            Text(isOn ? "✓ \(subscription.name)" : subscription.name)
                .font(.callout.weight(isOn ? .medium : .regular))
                .foregroundStyle(isOn ? Palette.accentText : Palette.label2)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, 2)
                .background(isOn ? Palette.accentTint : .clear, in: Capsule())
                .overlay { if !isOn { Capsule().strokeBorder(Palette.separator2, lineWidth: 0.5) } }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(help(subscription, isOn: isOn, isLocked: isLocked))
        .accessibilityLabel(Text(subscription.name))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("retention.subscription.\(subscription.id)")
    }

    private func help(_ subscription: RetentionSubscription, isOn: Bool, isLocked: Bool) -> String {
        if isLocked {
            return String(localized: "\(subscription.name) shows this message. To change that, give it another message.")
        }
        if !isOn, let other = model.otherMessage(showing: subscription.id) {
            return String(localized: "\(subscription.name) shows “\(other.referenceName)” now; checking it here replaces that one.")
        }
        return isOn ? String(localized: "Shows this message") : String(localized: "Show this message to \(subscription.name) subscribers")
    }
}
