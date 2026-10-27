//
//  ConnectHelpSteps.swift
//  AppLocalizer
//

import SwiftUI

/// "Where do I find these?": how to create a team API key that can edit
/// prices and store text.
struct ConnectHelpSteps: View {
    static let integrationsURL = URL(string: "https://appstoreconnect.apple.com/access/integrations/api")!

    private let steps: [LocalizedStringKey] = [
        "In App Store Connect, open **Users and Access → Integrations → App Store Connect API**.",
        "Under **Team Keys**, generate a key with the **Admin** or **App Manager** role. Price suggestions also read Sales and Trends when the role allows it.",
        "Copy the **Issuer ID** shown above the keys table, and the new key’s **Key ID**.",
        "Download the `.p8` file. Apple offers the download only once, so keep a copy somewhere safe.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xSmall) {
                    Text(verbatim: "\(index + 1).")
                        .monospacedDigit()
                        .frame(minWidth: 14, alignment: .trailing)
                    Text(step)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Link(destination: Self.integrationsURL) {
                Label("Open App Store Connect", systemImage: "arrow.up.forward.square")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .padding(.leading, Spacing.xLarge)
            .padding(.top, Spacing.tiny)
            .accessibilityIdentifier("connect.openAppStoreConnectLink")
        }
        .font(.callout)
        .padding(.top, Spacing.small)
    }

    /// "Open App Store Connect ↗": the icon after the title.
    private struct TrailingIconLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 4) {
                configuration.title
                configuration.icon
                    .imageScale(.small)
            }
        }
    }
}

#Preview {
    ConnectHelpSteps()
        .padding()
        .frame(width: 480)
}
