//
//  MCPPrivacyScanDetails.swift
//  AppLocalizer
//

import Foundation

/// `propose_privacy_answers`' `scan`: what the assistant read (repository,
/// commit, SDKs, privacy manifests) and what it couldn't see, for the scan
/// summary.
enum MCPPrivacyScanDetails {
    static func scan(_ object: [String: JSONValue], client: String, at date: Date) -> PrivacyScan {
        let sdks = (object["sdks"]?.arrayValue ?? []).compactMap { value -> PrivacySDK? in
            if let name = value.stringValue { return PrivacySDK(name: name, version: nil) }
            guard let sdk = value.objectValue, let name = sdk["name"]?.stringValue else { return nil }
            return PrivacySDK(name: name, version: sdk["version"]?.stringValue)
        }
        let manifests = (object["manifests_read"]?.arrayValue ?? object["manifests"]?.arrayValue ?? []).compactMap(\.stringValue)
        return PrivacyScan(
            assistant: client,
            repository: object["repository"]?.stringValue,
            commit: object["commit"]?.stringValue,
            ranAt: date,
            sdks: sdks,
            manifestsRead: manifests,
            trackingSignals: object["tracking_signals"]?.stringValue,
            couldNotSee: object["could_not_see"]?.stringValue
        )
    }
}
