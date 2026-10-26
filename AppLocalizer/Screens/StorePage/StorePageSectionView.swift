//
//  StorePageSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The Store Page section of an app's workspace (⌘3).
struct StorePageSectionView: View {
    let app: StoreApp
    let services: any StorePageServices

    var body: some View {
        ContentUnavailableView("Store Page", systemImage: "globe", description: Text("Coming soon."))
            .accessibilityIdentifier("workspace.storePage")
    }
}
