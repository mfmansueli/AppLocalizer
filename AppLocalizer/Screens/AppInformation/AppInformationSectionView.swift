//
//  AppInformationSectionView.swift
//  AppLocalizer
//

import SwiftUI

/// The App Information section of an app's workspace (⌘4).
struct AppInformationSectionView: View {
    let app: StoreApp
    let services: any AppInformationServices

    var body: some View {
        ContentUnavailableView("App Information", systemImage: "info.circle", description: Text("Coming soon."))
            .accessibilityIdentifier("workspace.appInformation")
    }
}
