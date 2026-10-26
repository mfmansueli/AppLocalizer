//
//  ConnectHelpSteps.swift
//  AppLocalizer
//

import SwiftUI

/// "Where do I find these?": how to create a team API key that can edit
/// prices and store metadata.
struct ConnectHelpSteps: View {
    static let integrationsURL = URL(string: "https://appstoreconnect.apple.com/access/integrations/api")!

    private let steps: [LocalizedStringKey] = [
        "In App Store Connect, open **Users and Access → Integrations → App Store Connect API**.",
        "Under **Team Keys**, generate a key with the **Admin** or **App Manager** role. Prices and store listings can't be edited with less.",
        "Copy the **Issuer ID** shown above the list, and the new key's **Key ID**.",
        "Download the key (**AuthKey_….p8**). Apple only offers the download once, so keep the file somewhere safe.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Text(step)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Link("Open App Store Connect", destination: Self.integrationsURL)
                .accessibilityIdentifier("connect.openAppStoreConnectLink")
        }
        .font(.callout)
        .padding(.top, 6)
    }
}

#Preview {
    ConnectHelpSteps()
        .padding()
        .frame(width: 480)
}
