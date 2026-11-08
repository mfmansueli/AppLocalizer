//
//  RetentionIntroBanner.swift
//  AppLocalizer
//

import SwiftUI

/// Where the message appears, what Apple keeps, and a link to Apple's guide.
struct RetentionIntroBanner: View {
    static let guideURL = URL(string: "https://developer.apple.com/help/app-store-connect/manage-subscriptions/configure-retention-messages/")

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.medium) {
            Text("""
            Apple shows one message from you on its Confirm Cancellation screen, on iOS and iPadOS 15.1, macOS 14 and \
            visionOS 1 or later. The Cancel button always stays, and the message is marked as coming from you. \
            Messages and offers go through App Review.
            """)
            .font(.callout)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            if let url = Self.guideURL {
                Link(destination: url) {
                    Text("Apple’s guide \(Image(systemName: "arrow.up.right"))")
                        .font(.caption)
                }
                .accessibilityIdentifier("retention.guide")
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Palette.fill2, in: RoundedRectangle(cornerRadius: Radius.field, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("retention.intro")
    }
}
