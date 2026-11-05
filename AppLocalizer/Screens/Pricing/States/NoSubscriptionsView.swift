//
//  NoSubscriptionsView.swift
//  AppLocalizer
//

import SwiftUI

/// What Pricing shows for an app that sells nothing yet: Create
/// Subscription, Ask Claude Code to set up the ones the app's code sells,
/// and the new subscriptions already waiting in Review & Push.
struct NoSubscriptionsView: View {
    @Bindable var viewModel: PricingViewModel

    @Environment(\.openURL) private var openURL

    // The queued list goes in the actions: a fixed-size ContentUnavailableView
    // above it made the window's minimum height follow the description's
    // wrapping, and AppKit's layout looped until it crashed.
    var body: some View {
        ContentUnavailableView {
            Label("\(viewModel.app.name) has no subscriptions", systemImage: "tag")
        } description: {
            Text(description)
        } actions: {
            VStack(spacing: Spacing.xLarge) {
                HStack(spacing: Spacing.small) {
                    Button("Create Subscription…") { viewModel.isNewSubscriptionSheetPresented = true }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("pricing.createSubscription")
                    NewSubscriptionAskButton(app: viewModel.app)
                    Button("Open App Store Connect") {
                        if let url = URL(string: "https://appstoreconnect.apple.com/apps") { openURL(url) }
                    }
                    .accessibilityIdentifier("pricing.openAppStoreConnect")
                }
                .buttonBorderShape(.capsule)
                if !viewModel.queuedNewSubscriptions.isEmpty {
                    QueuedNewSubscriptionsList(viewModel: viewModel)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: 520)
        .padding(Spacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.noSubscriptions")
    }

    private var description: String {
        viewModel.queuedNewSubscriptions.isEmpty
            ? String(localized: """
            Create one here or ask your assistant to set up the ones the app’s code sells. They wait in Review & \
            Push, and the push creates them with their texts, availability and starting price.
            """)
            : String(localized: "Push to create them, then refresh to set their prices here.")
    }
}
