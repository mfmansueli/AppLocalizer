//
//  PrivacyEvidence+Tracking.swift
//  AppLocalizer
//

import Foundation

extension PrivacyEvidence {
    /// Signs of tracking in the evidence: App Tracking Transparency, the
    /// advertising identifier, or a manifest that says it tracks.
    var suggestsTracking: Bool {
        let text = [entry, excerpt].compactMap(\.self).joined(separator: " ").lowercased()
        let signals = [
            "attrackingmanager", "asidentifiermanager", "advertisingidentifier", "nsusertrackingusagedescription",
            "nsprivacytracking: true", "nsprivacytracking = true", "nsprivacytrackingdomains", "tracking: true",
        ]
        return signals.contains { text.contains($0) }
    }
}
