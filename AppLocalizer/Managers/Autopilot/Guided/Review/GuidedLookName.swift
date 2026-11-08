//
//  GuidedLookName.swift
//  AppLocalizer
//

import Foundation

/// A look's or template's name without the app's, where the app is plain
/// already: Bruma's Review said "Look: Social Proof · for Bruma – Gay
/// Dating Nearby · saved as template v2, replacing Bruma – Gay Dating
/// Nearby · Caption above device (v1)".
enum GuidedLookName {
    /// "Social Proof · for Lumen" → "Social Proof"; "Lumen · Caption above
    /// device" → "Caption above device"; any other name as it is.
    static func short(_ name: String, app: String) -> String {
        guard !app.isEmpty else { return name }
        var name = name
        let suffix = AutopilotShotStyle.directionName(template: "", app: app)
        if name.hasSuffix(suffix), name.count > suffix.count { name.removeLast(suffix.count) }
        let prefix = "\(app) · "
        if name.hasPrefix(prefix), name.count > prefix.count { name.removeFirst(prefix.count) }
        return name
    }
}
