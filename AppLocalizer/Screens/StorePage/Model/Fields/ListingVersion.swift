//
//  ListingVersion.swift
//  AppLocalizer
//

import Foundation

/// The app version whose store page is being edited, as the version picker
/// shows it: "1.4 · Prepare for Submission".
struct ListingVersion: Identifiable, Hashable, Sendable {
    /// The version string, e.g. `1.4`.
    let versionString: String
    let state: ListingVersionState
    /// The app's first version has no What's New.
    let isFirstVersion: Bool

    init(_ versionString: String, state: ListingVersionState, isFirstVersion: Bool = false) {
        self.versionString = versionString
        self.state = state
        self.isFirstVersion = isFirstVersion
    }

    var id: String { versionString }

    /// Version-level fields can be changed. App-level fields can be
    /// changed even when no version is editable.
    var isEditable: Bool { state.isEditable }

    /// The context bar's title, e.g. "Version 1.4 · Prepare for Submission".
    var title: String { String(localized: "Version \(versionString) · \(state.title)") }

    /// The version picker's row, e.g. "1.4 · Prepare for Submission".
    var pickerTitle: String { "\(versionString) · \(state.title)" }

    /// The version picker's second line: "Editable" or "Live · read-only".
    var pickerSubtitle: String {
        if isEditable { return String(localized: "Editable") }
        return state.isLive ? String(localized: "Live · read-only") : String(localized: "Read-only")
    }
}
