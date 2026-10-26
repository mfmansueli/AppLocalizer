//
//  EmptyLocaleView.swift
//  AppLocalizer
//

import SwiftUI

/// A locale with no text at all, typically one just added: translate it
/// from the primary locale, or copy the URLs as they are.
struct EmptyLocaleView: View {
    let viewModel: StorePageViewModel
    let locale: StoreLocale

    var body: some View {
        let primary = viewModel.listing?.primaryLocale ?? .englishUS
        VStack(spacing: Spacing.small) {
            Image(systemName: "globe")
                .font(.system(size: 26))
                .foregroundStyle(Palette.label3)
                .accessibilityHidden(true)
            Text("\(locale.name) has no text yet")
                .font(.title3.weight(.semibold))
            Text("Translate it from \(primary.name), or copy from a sibling locale with Fill. URLs can be copied as they are.")
                .font(.callout)
                .foregroundStyle(Palette.label2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            HStack(spacing: Spacing.small) {
                Button("Translate from \(primary.name)…") {
                    viewModel.presentTranslate(locale: locale)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isVersionEditable)
                .accessibilityIdentifier("storePage.translateLocale")
                Button("Copy URLs from \(primary.languageName)") {
                    viewModel.copyURLs(to: locale)
                }
                .accessibilityIdentifier("storePage.copyURLs")
            }
            .padding(.top, Spacing.xxSmall)
        }
        .padding(Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("storePage.emptyLocale")
    }
}
