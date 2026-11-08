//
//  RevisionLabel.swift
//  AppLocalizer
//

import Foundation

/// What a design revision is called where the person sees it: "Revised",
/// never an engine number like "v2". Version 1 is what the design source
/// made first.
enum RevisionLabel {
    /// "First version", "Revised", "Revised 2 times".
    static func title(version: Int) -> String {
        switch version {
        case ..<2: String(localized: "First version")
        case 2: String(localized: "Revised")
        default: String(localized: "Revised \(version - 1) times")
        }
    }

    /// " · Revised" after a title, or nothing for the first version.
    static func suffix(version: Int?) -> String {
        guard let version, version > 1 else { return "" }
        return " · " + title(version: version)
    }
}
