//
//  NoSubscriptionsView.swift
//  AppLocalizer
//

import SwiftUI

/// What Pricing shows for an app that sells nothing yet.
struct NoSubscriptionsView: View {
    let appName: String

    @Environment(\.openURL) private var openURL

    var body: some View {
        ContentUnavailableView {
            Label("\(appName) has no subscriptions", systemImage: "tag")
        } description: {
            Text("""
            Create a subscription group or an in-app purchase in App Store Connect, then refresh. Until then \
            there’s nothing to price here, but Store Page and App Information work as usual.
            """)
        } actions: {
            Button("Open App Store Connect") {
                if let url = URL(string: "https://appstoreconnect.apple.com/apps") { openURL(url) }
            }
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("pricing.openAppStoreConnect")
        }
        .frame(maxWidth: 460)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pricing.noSubscriptions")
    }
}

#Preview {
    NoSubscriptionsView(appName: "Quiet Timer")
        .frame(width: 900, height: 600)
}
