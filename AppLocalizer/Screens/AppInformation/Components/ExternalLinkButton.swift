//
//  ExternalLinkButton.swift
//  AppLocalizer
//

import SwiftUI

/// "About the Labels ↗", "Criteria ↗": opens one of Apple's pages in the
/// browser. A bordered button, or a link inside a row.
struct ExternalLinkButton: View {
    let title: String
    let url: URL
    var isLink = false

    @Environment(\.openURL) private var openURL

    var body: some View {
        if isLink {
            button.buttonStyle(.link)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private var button: some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 3) {
                Text(title)
                Image(systemName: "arrow.up.right")
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text("Opens in your browser"))
        .help(url.absoluteString)
    }
}

#Preview {
    HStack {
        ExternalLinkButton(title: "About the Labels", url: AccessibilityFeature.overviewURL)
        ExternalLinkButton(title: "Criteria", url: AccessibilityFeature.voiceOver.criteriaURL, isLink: true)
    }
    .padding()
}
