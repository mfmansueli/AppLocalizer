//
//  AppInformationLoadErrorView.swift
//  AppLocalizer
//

import SwiftUI

/// A page that needs App Store Connect's values couldn't load them.
struct AppInformationLoadErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Couldn’t load app information"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
                .textSelection(.enabled)
        } actions: {
            Button(String(localized: "Try Again"), action: retry)
                .accessibilityIdentifier("appInformation.retry")
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("appInformation.loadError")
    }
}

#Preview {
    AppInformationLoadErrorView(message: "App Store Connect returned an error (500).") {}
        .frame(width: 600, height: 400)
}
