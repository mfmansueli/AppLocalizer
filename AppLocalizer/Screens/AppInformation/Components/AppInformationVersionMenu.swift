//
//  AppInformationVersionMenu.swift
//  AppLocalizer
//

import SwiftUI

/// Picks the version copyright, release and App Review belong to, like
/// the Store Page's version picker: each version with its state, and
/// "Editable" or "Live · read-only".
struct AppInformationVersionMenu: View {
    let versions: [StorePageVersion]
    let selected: StorePageVersion
    let onSelect: (StorePageVersion.ID) -> Void

    var body: some View {
        Menu {
            Section("Versions") {
                ForEach(versions) { version in
                    Button {
                        onSelect(version.id)
                    } label: {
                        if version.id == selected.id {
                            Image(systemName: "checkmark")
                        }
                        Text(version.pickerTitle(among: versions))
                        Text(version.listingVersion.pickerSubtitle)
                    }
                    .accessibilityIdentifier("appInformation.version.\(version.versionString)")
                }
            }
        } label: {
            Text(selected.pickerTitle(among: versions))
                .font(.caption)
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .fixedSize()
        .accessibilityLabel(Text("Version, \(selected.listingVersion.title)"))
        .accessibilityIdentifier("appInformation.versionMenu")
    }
}

#Preview {
    let versions = [
        StorePageVersion(id: "14", listingVersion: ListingVersion("1.4", state: .prepareForSubmission)),
        StorePageVersion(id: "13", listingVersion: ListingVersion("1.3", state: .readyForDistribution)),
    ]
    AppInformationVersionMenu(versions: versions, selected: versions[0]) { _ in }
        .padding()
}
