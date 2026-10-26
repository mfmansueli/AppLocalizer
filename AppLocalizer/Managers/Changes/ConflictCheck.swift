//
//  ConflictCheck.swift
//  AppLocalizer
//

import Foundation

/// How Review & Push notices that a value changed in App Store Connect since
/// it was fetched: before pushing, it `GET`s `path` and reads the string at
/// `keyPath` in the JSON response. When that differs from `expected`, the
/// change is shown as a conflict with both values instead of being pushed.
struct ConflictCheck: Hashable, Codable, Sendable {
    /// Path under `https://api.appstoreconnect.apple.com`, with any query.
    var path: String
    /// Keys into the response, array indices as numbers, e.g.
    /// `["data", "attributes", "subtitle"]` or `["included", "0", "attributes", "customerPrice"]`.
    var keyPath: [String]
    /// The value at the last fetch; nil when it was empty.
    var expected: String?
}
