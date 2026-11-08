//
//  RetentionEmptyState.swift
//  AppLocalizer
//

import SwiftUI

/// No retention message yet: what one does, Apple's early numbers, and
/// the two ways to start.
struct RetentionEmptyState: View {
    let model: RetentionModel

    var body: some View {
        Card(padding: Spacing.xxLarge) {
            VStack(spacing: Spacing.small) {
                Text("No retention message yet")
                    .font(.headline)
                Text(text)
                    .font(.callout)
                    .foregroundStyle(Palette.label2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 540)
                HStack(spacing: Spacing.small) {
                    Button("Create a Message", action: model.newMessage)
                        .buttonStyle(.borderedProminent)
                        .disabled(model.subscriptions.isEmpty)
                        .accessibilityIdentifier("retention.empty.create")
                    RetentionAskButton(app: model.app, kind: .draftOne)
                }
                .padding(.top, Spacing.xxSmall)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("retention.empty")
    }

    private var text: String {
        guard !model.subscriptions.isEmpty else {
            return String(localized: "Retention messages are for subscriptions. Create one in Prices first.")
        }
        let groups = Set(model.subscriptions.map(\.groupName))
        let what = groups.count == 1 ? groups.first ?? "" : String(localized: "the subscription")
        return String(localized: """
        Subscribers who tap Cancel Subscription see only Apple’s Confirm Cancellation screen. A message reminds them \
        what \(what) gives them, and a retention offer can keep them at a lower price. Apple’s early results: about \
        1.4 more of every 100 stay with a message, 5.5 with an offer.
        """)
    }
}
