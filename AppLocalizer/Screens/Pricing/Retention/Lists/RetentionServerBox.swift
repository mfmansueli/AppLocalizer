//
//  RetentionServerBox.swift
//  AppLocalizer
//

import SwiftUI

/// Advanced, folded: real-time messages from the developer's server with
/// Apple's Retention Messaging API. AppLocalizer explains it, links to
/// Apple's access request and hands the setup to Claude Code.
struct RetentionServerBox: View {
    let model: RetentionModel

    static let requestAccessURL = URL(string: "https://developer.apple.com/contact/request/retention-messaging-api/")

    var body: some View {
        @Bindable var model = model
        Card(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.snappy) { model.isAdvancedExpanded.toggle() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real-time from your server")
                                .font(.body.weight(.medium))
                            Text("Advanced · not set up")
                                .font(.caption)
                                .foregroundStyle(Palette.label2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.label3)
                            .rotationEffect(.degrees(model.isAdvancedExpanded ? 90 : 0))
                            .accessibilityHidden(true)
                    }
                    .padding(Spacing.medium)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(model.isAdvancedExpanded ? Text("Expanded") : Text("Collapsed"))
                .accessibilityIdentifier("retention.server.toggle")
                if model.isAdvancedExpanded { details }
            }
        }
        .accessibilityIdentifier("retention.server")
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("""
            Your server picks the message for each subscriber the moment they tap Cancel, and can suggest switching plan \
            (for example to annual) or sign a promotional offer. It has 700 ms to answer; if it doesn’t, Apple shows the \
            messages set here.
            """)
            Text("""
            Needs access from Apple and a performance test in the sandbox before it goes live. Uses the Retention \
            Messaging API, not the App Store Connect key AppLocalizer uses.
            """)
            HStack(spacing: Spacing.small) {
                if let url = Self.requestAccessURL {
                    Link(destination: url) {
                        Text("Request Access \(Image(systemName: "arrow.up.right"))")
                    }
                    .accessibilityIdentifier("retention.server.requestAccess")
                }
            }
            RetentionServerSetupButton(app: model.app)
        }
        .font(.callout)
        .foregroundStyle(Palette.label2)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, Spacing.medium)
        .padding(.bottom, Spacing.medium)
    }
}
