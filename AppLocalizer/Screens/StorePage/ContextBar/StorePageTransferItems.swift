//
//  StorePageTransferItems.swift
//  AppLocalizer
//

import SwiftUI

/// What the Import & Export menu offers.
struct StorePageTransferItems: View {
    @Bindable var viewModel: StorePageViewModel

    var body: some View {
        Button("Import Translations…") {
            viewModel.isImporterPresented = true
        }
        Divider()
        Section("For translators") {
            ForEach(ListingTransferFormat.allCases) { format in
                Button(format.exportTitle) {
                    viewModel.exportFormat = format
                }
            }
        }
    }
}
