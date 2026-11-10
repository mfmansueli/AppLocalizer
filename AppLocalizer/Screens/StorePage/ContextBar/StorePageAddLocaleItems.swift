//
//  StorePageAddLocaleItems.swift
//  AppLocalizer
//

import SwiftUI

/// What Add Locale offers: the languages the app supports first.
struct StorePageAddLocaleItems: View {
    let viewModel: StorePageViewModel

    var body: some View {
        let pending = viewModel.pendingLocales
        if !pending.isEmpty {
            Section("In the app, not on the App Store") {
                ForEach(pending) { locale in
                    Button(locale.name) {
                        viewModel.addLocale(locale)
                    }
                }
            }
        }
        Section("Add a locale") {
            ForEach(viewModel.addableLocales.filter { !pending.contains($0) }) { locale in
                Button(locale.name) {
                    viewModel.addLocale(locale)
                }
            }
        }
    }
}
