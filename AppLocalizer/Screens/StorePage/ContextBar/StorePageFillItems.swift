//
//  StorePageFillItems.swift
//  AppLocalizer
//

import SwiftUI

/// What the Fill menu offers: copying between sibling locales, the URLs and
/// What's New to every locale, and Find and Replace.
struct StorePageFillItems: View {
    let viewModel: StorePageViewModel

    var body: some View {
        Section("Copy from a sibling locale") {
            if viewModel.siblingPairs.isEmpty {
                Text("Nothing to copy")
            }
            ForEach(viewModel.siblingPairs, id: \.self) { pair in
                Button("\(pair.source.name) → \(pair.target.name)") {
                    viewModel.copy(pair)
                }
            }
        }
        Divider()
        Button("Copy URLs to Every Locale") {
            viewModel.copyURLsToEveryLocale()
        }
        .disabled(!viewModel.hasURLsToCopy)
        Button("Send What’s New to Every Locale…") {
            viewModel.presentWhatsNewBroadcast()
        }
        .disabled(viewModel.value(.whatsNew, in: viewModel.listing?.primaryLocale ?? .englishUS).isEmpty)
        Button("Find and Replace…") {
            viewModel.presentFindReplace()
        }
    }
}
