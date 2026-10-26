//
//  AppInfoAttributes.swift
//  AppLocalizer
//

import Foundation

/// The `appInfos` attributes the Store Page reads: which app info is the one
/// being prepared and which is live. `state` replaced `appStoreState`.
struct AppInfoAttributes: Decodable, Sendable {
    var appStoreState: String?
    var state: String?

    /// The newer state when Apple sends it, else the older one.
    var currentState: String? { state ?? appStoreState }
}
