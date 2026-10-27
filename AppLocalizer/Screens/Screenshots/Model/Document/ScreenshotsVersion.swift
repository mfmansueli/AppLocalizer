//
//  ScreenshotsVersion.swift
//  AppLocalizer
//

import Foundation

/// The App Store version screenshots go live with. Screenshots can only
/// change on a version that's being prepared; otherwise renders wait and
/// pushing is off.
struct ScreenshotsVersion: Hashable, Sendable {
    var id: String?
    /// "1.4".
    var versionString: String
    /// "Prepare for Submission".
    var stateTitle: String
    var isEditable: Bool

    /// "Version 1.4 · Prepare for Submission".
    var title: String {
        String(localized: "Version \(versionString) · \(stateTitle)")
    }
}
