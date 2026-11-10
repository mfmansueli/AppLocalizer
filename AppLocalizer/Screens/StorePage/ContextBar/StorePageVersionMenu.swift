//
//  StorePageVersionMenu.swift
//  AppLocalizer
//

import SwiftUI

/// Which version's texts the Store Page shows, in its header.
struct StorePageVersionMenu: View {
    let viewModel: StorePageViewModel

    var body: some View {
        if let content = viewModel.content {
            Menu {
                Section("Versions") {
                    ForEach(content.versions) { version in
                        Button {
                            Task { await viewModel.selectVersion(version.id) }
                        } label: {
                            if version.id == content.version.id {
                                Image(systemName: "checkmark")
                            }
                            Text(version.pickerTitle(among: content.versions))
                            Text(version.listingVersion.pickerSubtitle)
                        }
                        .accessibilityIdentifier("storePage.version.\(version.versionString)")
                    }
                }
            } label: {
                Text(content.version.title(among: content.versions))
            }
            .fixedSize()
            .accessibilityLabel(Text("Version, \(content.version.listingVersion.title)"))
            .accessibilityIdentifier("storePage.versionPicker")
        }
    }
}
