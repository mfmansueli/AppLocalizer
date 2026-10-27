//
//  ReadOnlyVersionNote.swift
//  AppLocalizer
//

import SwiftUI

/// Under a version's values when that version can't change: "1.3 is live,
/// so these can't change here. Pick 1.4 in the version menu to edit."
struct ReadOnlyVersionNote: View {
    let version: StorePageVersion
    let editable: StorePageVersion?

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lock")
        }
        .font(.caption)
        .foregroundStyle(Palette.label2)
        .padding(.horizontal, Spacing.medium + 2)
        .padding(.vertical, Spacing.small)
        .accessibilityIdentifier("appInformation.readOnlyVersion")
    }

    private var text: String {
        let state = version.state.isLive ? String(localized: "is live") : String(localized: "is \(version.state.title.lowercased())")
        let first = String(localized: "\(version.versionString) \(state), so these can’t change here.")
        guard let editable else { return first + " " + String(localized: "Create a new version in App Store Connect to edit them.") }
        return first + " " + String(localized: "Pick \(editable.versionString) in the version menu to edit.")
    }
}

#Preview {
    ReadOnlyVersionNote(
        version: StorePageVersion(id: "13", listingVersion: ListingVersion("1.3", state: .readyForDistribution)),
        editable: StorePageVersion(id: "14", listingVersion: ListingVersion("1.4", state: .prepareForSubmission))
    )
    .frame(width: 500)
}
