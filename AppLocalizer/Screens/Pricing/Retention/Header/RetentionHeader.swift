//
//  RetentionHeader.swift
//  AppLocalizer
//

import SwiftUI

/// "Retention", what it is, Prices | Retention, Ask Claude Code… and
/// New Message.
struct RetentionHeader: View {
    let model: RetentionModel
    @Binding var page: PricingPage
    /// Nil in previews and scenes without the app's gate.
    @Environment(ProGate.self) private var pro: ProGate?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text("Retention")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            HStack(spacing: Spacing.small) {
                RetentionPageSwitch(page: $page)
                RetentionAskButton(app: model.app, kind: .draft)
                Button {
                    pro.require(.retention) { model.newMessage() }
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Label("New Message", systemImage: "plus")
                        if pro.isFree { ProChip() }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canAddMessage || model.subscriptions.isEmpty)
                .help(model.canAddMessage
                    ? String(localized: "A new message, empty: write \(model.sourceLocale.name) first, then Translate All")
                    : String(localized: "An app can have \(RetentionLimits.messagesPerApp) retention messages"))
                .accessibilityIdentifier("retention.newMessage")
            }
            .fixedSize()
        }
        .accessibilityElement(children: .contain)
    }

    /// "What Lumen Plus subscribers see after they tap Cancel Subscription,
    /// in every language."
    private var subtitle: String {
        let groups = Set(model.subscriptions.map(\.groupName))
        if groups.count == 1, let group = groups.first {
            return String(localized: "What \(group) subscribers see after they tap Cancel Subscription, in every language.")
        }
        return String(localized: "What subscribers see after they tap Cancel Subscription, in every language.")
    }
}
