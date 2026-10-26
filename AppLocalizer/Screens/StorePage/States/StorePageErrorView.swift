//
//  StorePageErrorView.swift
//  AppLocalizer
//

import SwiftUI

/// Loading failed and there's nothing to show yet: why, and Try Again.
struct StorePageErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t load the store page", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .accessibilityIdentifier("storePage.retry")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.loadError")
    }
}
